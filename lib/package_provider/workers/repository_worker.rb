require 'package_provider/repository_connection_pool'
require 'package_provider/repository_config'
# Package provider module
module PackageProvider
  # class performing caching repository as background job
  class RepositoryWorker
    include Sidekiq::Worker
    sidekiq_options queue: :clone_repository,
                    retry: PackageProvider.config.sidekiq.clone_retry_on_error

    def perform(repo, treeish, paths, use_submodules = false)
      PackageProvider.logger.info(
        "performing clonning: #{repo} #{treeish} #{paths} #{use_submodules}")

      repo_config = PackageProvider::RepositoryConfig.find(repo)
      c_pool = ReposPool.fetch(repo)

      PackageProvider.logger.debug("pool #{c_pool.inspect}")

      c_pool.with(timeout: repo_config[:timeout]) do |i|
        begin
          i.cached_clone(treeish, paths, use_submodules)
        rescue PackageProvider::CachedRepository::CloneInProgress
          PackageProvider.logger.info(
            "clone in progress: #{repo} #{treeish} #{paths} #{use_submodules}")
        end
      end
      PackageProvider.logger.info(
        "clonning done #{repo} {treeish} #{paths} #{use_submodules}")
    end
  end
end
