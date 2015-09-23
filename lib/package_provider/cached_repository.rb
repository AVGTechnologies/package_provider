require 'digest'
require 'timeout'
require 'package_provider/repository'

module PackageProvider
  # Class representing cached repository to avoid multiple cloninng
  class CachedRepository < PackageProvider::Repository
    class CloneInProgress < StandardError
    end

    class << self
      def cached?(treeish, paths, use_submodules = false)
        dir = cache_dir(treeish, paths, use_submodules)
        repo_ready?(dir)
      end

      def in_progress?(treeish, paths, use_submodules = false)
        dir = cache_dir(treeish, paths, use_submodules)
        File.exist?("#{dir}.clone_lock")
      end

      def cache_dir(treeish, paths, use_submodules)
        @sha256 ||= Digest::SHA256.new
        h = { treeish: treeish, paths: paths, submodule: use_submodules }

        digest = @sha256.hexdigest h.to_json

        File.join(PackageProvider.config.repository_cache_root, digest)
      end

      def repo_ready?(path)
        Dir.exist?(path) && File.exist?("#{path}.package_part_ready") &&
          !File.exist?("#{path}.clone_lock")
      end
    end

    def cached_clone(treeish, paths, use_submodules = false)
      cached_dir = CachedRepository.cache_dir(treeish, paths, use_submodules)
      if CachedRepository.repo_ready?(cached_dir)
        Metriks.meter('packageprovider.repository.cached').mark
        Metriks.meter("packageprovider.repository.#{metriks_key}.cached").mark
        return cached_dir
      end

      locked_file = lock_repo(cached_dir)

      begin
        logger.info("Started clonning: #{treeish} #{paths.inspect} " \
          "#{use_submodules} into #{cached_dir}")
        clone(cached_dir, treeish, paths, use_submodules)
      rescue PackageProvider::Repository::CannotCloneRepo => err
        repo_error!(cached_dir, err)
      rescue PackageProvider::Repository::CannotFetchRepo => err
        repo_error!(cached_dir, err)
      rescue => err
        logger.error("Expeption when clonning: #{treeish} #{paths.inspect} " \
          "#{use_submodules} into #{cached_dir} err: #{err}")
        FileUtils.rm_rf(cached_dir)
        raise
      end

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
  end
end
