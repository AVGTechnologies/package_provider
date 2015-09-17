require 'active_support/core_ext/hash/indifferent_access'

module PackageProvider
  # class for handling available local repo paths from config
  class RepositoryConfig
    CONFIG_FILE = -> { "#{PackageProvider.root}/config/repository_config.yml" }

    class << self
      def config_hash
        @config_hash ||=
          YAML.load(File.read(CONFIG_FILE.call))
          .with_indifferent_access[PackageProvider.env] || {}
      end

      def repositories
        config_hash[:repositories]
      end

      def defaults
        config_hash[:defaults]
      end

      def find(repo_url)
        defaults.merge(repositories[repo_url] || {})
      end
    end
  end
end
