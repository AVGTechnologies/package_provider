require 'digest'
require 'timeout'
require_relative 'repository'

module PackageProvider
  # Class representing cached repository to avoid multiple cloninng
  class CachedRepository < PackageProvider::Repository
    class CloneInProgress < StandardError
    end

    def cached_clone(treeish, paths, use_submodules = false)
      cached_dir = repo_cache_dir(treeish, paths, use_submodules)
      return cached_dir if repo_ready?(cached_dir)

      locked_file = nil
      begin
        locked_file = lock_repo(cached_dir)
      rescue Timeout::Error
        return cached_dir if repo_ready?(cached_dir)
        raise CloneInProgress
      end

      begin
        log_clone(cached_dir, treeish, paths, use_submodules)
        clone(cached_dir, treeish, paths, use_submodules)
      rescue => err
        log_error(err, cached_dir, treeish, paths, use_submodules)
        FileUtils.rm_rf(cached_dir)
        raise
      end

      repo_ready!(cached_dir)
      cached_dir
    ensure
      log_unlock_repo(treeish, paths, use_submodules)
      unlock_repo(locked_file)
    end

    private

    def lock_repo(path)
      Timeout.timeout(2) do
        lock_file = "#{path}.clone_lock"
        f = File.open(lock_file, File::RDWR | File::CREAT, 0644)
        f.flock(File::LOCK_EX)
        f
      end
    end

    def unlock_repo(f)
      return unless f
      f.flock(File::LOCK_UN)
      File.delete(f.path)
    end

    def repo_cache_dir(treeish, paths, use_submodules)
      @sha256 ||= Digest::SHA256.new
      h = { treeish: treeish, paths: paths, submodule: use_submodules }

      digest = @sha256.hexdigest h.to_json

      File.join(PackageProvider.config.repository_cache_root, digest)
    end

    def repo_ready?(path)
      Dir.exist?(path) && File.exist?("#{path}.package_part_ready") &&
        !File.exist?("#{path}.clone_lock")
    end

    def repo_ready!(path)
      FileUtils.touch("#{path}.package_part_ready")
    end

    def log_error(err, dir, treeish, paths, use_submodules)
      PackageProvider.logger.error(
        "Expeption when clonning: #{treeish} #{paths.inspect} " \
        "#{use_submodules} into #{dir} err: #{err}")
    end

    def log_clone(dir, treeish, paths, use_submodules)
      PackageProvider.logger.debug(
        "Started clonning: #{treeish} #{paths.inspect} #{use_submodules} " \
        "into #{dir}")
    end

    def log_unlock_repo(treeish, paths, use_submodules)
      PackageProvider.logger.debug(
        "Unlocked file for: #{treeish} #{paths.inspect} #{use_submodules}")
    end
  end
end
