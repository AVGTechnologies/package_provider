require 'digest'
require 'timeout'
require 'package_provider/repository'

module PackageProvider
  # Class representing cached repository to avoid multiple cloninng
  class CachedRepository < PackageProvider::Repository
    class CloneInProgress < StandardError
    end

    class RepoServantDoesNotMatch < StandardError
    end

    class << self
      def cached?(req)
        dir = cache_dir(req)
        repo_ready?(dir)
      end

      def in_progress?(req)
        dir = cache_dir(req)
        File.exist?("#{dir}.clone_lock")
      end

      def cache_dir(req)
        @sha256 ||= Digest::SHA256.new
        h = { treeish: req.commit_hash,
              paths: req.checkout_mask,
              submodule: req.submodules? }

        digest = @sha256.hexdigest h.to_json

        File.join(PackageProvider.config.repository_cache_root, digest)
      end

      def repo_ready?(path)
        Dir.exist?(path) && File.exist?("#{path}.package_part_ready") &&
          !File.exist?("#{path}.clone_lock")
      end
    end

    def cached_clone(req)
      fail RepoServantDoesNotMatch unless req.repo == @repo_url
      cached_dir = CachedRepository.cache_dir(req)
      if CachedRepository.repo_ready?(cached_dir)
        Metriks.meter('packageprovider.repository.cached').mark
        Metriks.meter("packageprovider.repository.#{metriks_key}.cached").mark
        return cached_dir
      end

      locked_file = lock_repo(cached_dir)
      perform_and_handle_clone(req, cached_dir)
      repo_ready!(cached_dir)

      cached_dir
    ensure
      unlock_repo(locked_file)
    end

    private

    def logger
      PackageProvider.logger
    end

    def lock_repo(path)
      Timeout.timeout(2) do
        lock_file = "#{path}.clone_lock"
        f = File.open(lock_file, File::RDWR | File::CREAT, 0644)
        f.flock(File::LOCK_EX)
        logger.info("Locking file #{lock_file}")
        f
      end
    rescue Timeout::Error
      Metriks.meter('packageprovider.repository.locked').mark
      Metriks.meter("packageprovider.repository.#{metriks_key}.locked").mark
      raise CloneInProgress
    end

    def repo_error!(path, message)
      File.open("#{path}.error", 'w+') do |f|
        f.puts(message)
      end
    end

    def unlock_repo(f)
      return unless f
      f.flock(File::LOCK_UN)
      logger.info("Unlocking file #{f.path}")
      File.delete(f.path)
    end

    def repo_ready!(path)
      FileUtils.touch("#{path}.package_part_ready")
    end

    def perform_and_handle_clone(req, cached_dir)
      logger.info("Started clonning: #{req.inspect}")
      clone(cached_dir, req.commit_hash, req.checkout_mask, req.submodules?)
    rescue PackageProvider::Repository::CannotCloneRepo => err
      repo_error!(cached_dir, err)
    rescue PackageProvider::Repository::CannotFetchRepo => err
      repo_error!(cached_dir, err)
    rescue => err
      logger.error(
        "Clone exception: #{req.inspect} into #{cached_dir} err: #{err}")
      FileUtils.rm_rf(cached_dir)
      raise
    end
  end
end
