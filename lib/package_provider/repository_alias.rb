require 'active_support/core_ext/hash/indifferent_access'

module PackageProvider
  # class for handling available aliases from config
  class RepositoryAlias
    attr_reader :url, :alias

    CONFIG_FILE = -> { "#{PackageProvider.root}/config/repository_aliases.yml" }

    def initialize(url, repo_alias)
      @url = url
      @alias = repo_alias
    end

    def as_json
      [:url, :alias]
    end

    def to_json(options = {})
      MultiJson.dump({ url: @url, alias: @alias }, options)
    end

    class << self
      def aliases_hash
        return @aliases_hash if defined?(@aliases_hash) && @aliases_hash
        content = File.read(CONFIG_FILE.call)
        @aliases_hash =
          YAML.load(content)
          .with_indifferent_access[PackageProvider.env][:aliases] || {}
      end

      def reload!
        @aliases_hash = nil
        aliases_hash
      end

      def all
        aliases_hash.inject([]) { |s, (ali, url)| s << new(url, ali) }
      end

      def find(ali)
        all.find { |t| t.alias == ali }
      end
    end
  end
end
