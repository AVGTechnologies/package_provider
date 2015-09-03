require 'active_support/core_ext/hash/indifferent_access'

module PackageProvider
  # class for handling available aliases from config
  class RepositoryAlias
    attr_reader :url, :alias

    class NotFound < StandardError
    end

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
        sym = PackageProvider.env.to_sym
        @aliases_hash =
          YAML.load(content)[sym][:aliases].with_indifferent_access || {}
      end

      def reload!
        @aliases_hash = nil
        aliases_hash
      end

      def all
        aliases_hash.inject([]) { |s, (ali, url)| s << new(url, ali) }
      end

      def find(ali)
        res = all.find { |t| t.alias == ali }
        res ? res : fail(
          NotFound, "Couldn't find RepositoryAlias with alias=#{ali.inspect}")
      end
    end
  end
end
