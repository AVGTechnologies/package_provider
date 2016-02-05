require 'timeout'
require 'package_provider/cached_repository'
require 'package_provider/package_packer'
require 'package_provider/repository_config'

module PackageProvider
  # Class representing cached repository to avoid multiple cloninng
  class CachedPackage
    class PackingInProgress < StandardError
    end

    PACKAGE_READY = '.package_ready'
    PACKAGE_CLONE_LOCK = '.package_clone_lock'
    ERROR = '.error'

    class << self
      def from_cache(package_hash)
        return nil unless package_ready?(package_hash)
        Metriks.meter('packageprovider.package.cached').mark
        package_fullpath(package_hash)
      end

      def package_ready?(package_hash)
        path = package_directory(package_hash)

        Dir.exist?(path) && File.exist?(path + PACKAGE_READY) &&
          File.exist?(package_fullpath(package_hash)) &&
          !File.exist?(path + PACKAGE_CLONE_LOCK)
      end

      def package_directory(package_hash)
        File.join(PackageProvider.config.package_cache_root, package_hash)
      end

      def errors(package_hash)
        error_file_path = package_directory(package_hash) + ERROR
        return nil unless File.exist?(error_file_path)
        File.read(error_file_path)
      end

      private

      def package_fullpath(package_hash)
        File.join(package_directory(package_hash), 'package.zip')
      end
    end

    attr_reader :package_request

    def initialize(package_request, package_hash)
      @package_request = package_request
      @path = CachedPackage.package_directory(package_hash)
      @locked_package_file = nil
    end

    def cache_package
      lock_package
      if File.exist?(@path + PACKAGE_READY)
        Metriks.meter('packageprovider.package.cached').mark
        return
      end
      begin
        FileUtils.mkdir_p(@path)
        pack
        package_ready!
      rescue => err
        PackageProvider.logger.error("Create package failed: #{err}")
        Metriks.meter('packageprovider.package.error').mark
        package_error!(err)
        FileUtils.rm_rf(@path)
      end
    ensure
      unlock_package
    end

    private

    def logger
      PackageProvider.logger
    end

    def pack
      packer = PackageProvider::PackagePacker.new(@path)
      errors = []
      @package_request.each do |req|
        checkout_dir = PackageProvider::CachedRepository.cache_dir(req)

        error = load_repo_error(checkout_dir, req)
        errors << error if error
        next unless errors.empty?

        req.folder_override.each { |fo| packer.add_folder(checkout_dir, fo) }
      end

      errors.empty? ? packer.flush : package_error!(errors)
    end

    def package_ready!
      FileUtils.touch(@path + PACKAGE_READY)
    end

    def package_error!(message)
      File.open(@path + ERROR, 'w+') { |f| f.puts(message.to_json) }
    end

    def lock_package
      Timeout.timeout(2) do
        file = @path + PACKAGE_CLONE_LOCK
        locked_file = File.open(file, File::RDWR | File::CREAT, 0644)
        locked_file.flock(File::LOCK_EX)
        logger.info("Lock package #{file}")
        @locked_package_file = locked_file
      end
    rescue Timeout::Error
      Metriks.meter('packageprovider.package.locked').mark
      raise PackingInProgress
    end

    def unlock_package
      logger.info('Unlocking package')
      return unless @locked_package_file
      logger.info("Delete file #{@locked_package_file.path}")
      File.delete(@locked_package_file.path)
    end

    def load_repo_error(path, req)
      file_path = path + PackageProvider::CachedRepository::ERROR
      return unless File.exist?(file_path)
      { repository: req.to_tsd, error: File.read(file_path) }
    end
  end
end
