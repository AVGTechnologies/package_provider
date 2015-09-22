require 'active_support/time'
require 'package_provider/cached_repository'
require 'package_provider/cached_package'
require 'package_provider/workers/repository_worker'
require 'package_provider/request_parser/parser'

module PackageProvider
  # Class maintaining finishing package
  class PackerWorker
    include Sidekiq::Worker
    sidekiq_options queue: :package_packer,
                    retry: PackageProvider.config.sidekiq.packer_retry_on_error

    def perform(package_request_as_json)
      PackageProvider.logger.info(
        "Performing packing for: #{package_request_as_json}")

      parser = PackageProvider::Parser.new
      package_request = parser.parse_json(package_request_as_json)

      waiting_for_repo = false
      package_request.each { |req| waiting_for_repo ||= check_request(req) }

      if waiting_for_repo
        reschedule(package_request_as_json)
      else
        begin
          CachedPackage.new(package_request).cache_package
        rescue PackageProvider::CachedPackage::PackingInProgress
          PackageProvider.logger.info(
            "Packing in progress #{package_request_as_json}")
        end
      end
    end

    private

    def reschedule(package_request_as_json)
      PackageProvider.logger.info(
        "packing reschedule #{package_request_as_json}")

      PackerWorker.perform_in(
        PackageProvider.config.sidekiq.packer_reschedule_time.seconds,
        package_request_as_json)
    end

    def check_request(req)
      return false if PackageProvider::CachedRepository.cached?(
        req.commit_hash, req.checkout_mask, req.submodules?)

      return false if PackageProvider::CachedRepository.in_progress?(
        req.commit_hash, req.checkout_mask, req.submodules?)

      PackageProvider.logger.debug(
        "scheduling clonning #{req.inspect}")

      PackageProvider::RepositoryWorker.perform_async(
        req.repo, req.commit_hash, req.checkout_mask, req.submodules?)

      true
    end
  end
end
