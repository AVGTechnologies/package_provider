require 'connection_pool'
require 'package_provider/cached_repository'

module PackageProvider
  # Prepared repositories on application start
  class RepositoryConnectionPool
    def initialize
      @repos = {}
    end

    def fetch(req)
      repo_config = PackageProvider::RepositoryConfig.find(req.repo)
      @repos[req.repo] ||= ConnectionPool.new(
        size: repo_config[:pool_size],
        timeout: repo_config[:timeout]
      ) do
        begin
          PackageProvider.logger.debug(
            "Creating instance of #{req.repo} from #{repo_config.inspect}")

          PackageProvider::CachedRepository.new(req.repo, repo_config[:cache_dir])
        rescue PackageProvider::Repository::CannotInitRepo
          write_repo_error(req, 'Cannot clone repo: check repo url or server availability')
          raise
        rescue => err
          write_repo_error(req, "Cannot clone repo: #{err}")
          raise
        end
      end
    end

    def destroy
      @repos.each { |_key, value| value.shutdown(&:destroy) }
      @repos = {}
    end

    def write_repo_error(req, message)
      repo_path = PackageProvider::CachedRepository.cache_dir(req)

      PackageProvider::CachedRepository.repo_ready!(repo_path)
      PackageProvider::CachedRepository.repo_error!(repo_path, message)
    end
  end
end
