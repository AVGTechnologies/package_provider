require 'active_support/core_ext/hash/indifferent_access'

module PackageProvider
  # class for handling available local repo paths from config
  class RepositoryCacheList
    CONFIG_FILE = -> { "#{PackageProvider.root}/config/repository_cache.yml" }

    class << self
      def repository_cache_hash
        @repository_cache_hash ||=
          YAML.load(File.read(CONFIG_FILE.call))
          .with_indifferent_access[PackageProvider.env][:local_repo_paths] || {}
      end

      def find(repo_url)
        repository_cache_hash[repo_url]
      end
    end
  end
end
