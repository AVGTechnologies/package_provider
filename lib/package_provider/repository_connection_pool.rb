require 'connection_pool'
require 'package_provider/cached_repository'

module PackageProvider
  # Prepared repositories on application start
  class RepositoryConnectionPool
    def initialize
      @repos = {}
    end

    def fetch(repo)
      repo_config = PackageProvider::RepositoryConfig.find(repo)
      @repos[repo] ||= ConnectionPool.new(
        size: repo_config[:pool_size],
        timeout: repo_config[:timeout]
      ) do
        PackageProvider::CachedRepository.new(
          repo,
          repo_config[:cache_dir]
        )
      end
    end

    def destroy
      @repos.each { |_key, value| value.shutdown(&:destroy) }
      @repos = {}
    end
  end
end
