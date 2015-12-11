require 'multi_json'
require 'digest'
require 'package_provider/repository_alias'

module PackageProvider
  # Help class providing information abou package part to be returned
  class RepositoryRequest
    # Help class providing information abou folder override
    class FolderOverride
      attr_reader :source, :destination

      def initialize(source, destination = nil)
        @source = source.to_s.empty? ? nil : source.strip
        @destination = destination.to_s.empty? ? nil : destination.strip
      end

      def as_json
        {
          source: source,
          destinationOverride: destination
        }
      end

      def to_json(options = {})
        MultiJson.dump(as_json, options)
      end

      def ==(other)
        source == other.source && destination == other.destination
      end

      def normalize!
        source.tr!('\\', '/')
        destination.tr!('\\', '/') if destination
      end

      def valid?
        source_valid? && destination_valid?
      end

      def errors
        errors = []
        errors.concat source_errors unless source_errors.empty?
        errors.concat destinaton_errors unless destinaton_errors.empty?
        errors
      end

      def to_tsd
        return source unless destination
        "#{source}>#{destination}"
      end

      private

      def destinaton_errors
        errors = []

        unless destination_start_valid?
          errors << 'Destination can not start with \\ or /'
        end

        unless path_valid?(destination)
          errors << 'Destination can not contain \\\\ or //'
        end

        errors
      end

      def source_errors
        errors = []
        errors << 'Source is missing' unless source_present?
        errors << 'Source can not contain \\\\ or //' unless path_valid?(source)
        errors
      end

      def destination_valid?
        destination_start_valid? && path_valid?(destination)
      end

      def destination_start_valid?
        !destination.to_s.start_with?('/', '\\')
      end

      def source_valid?
        source_present? && path_valid?(source)
      end

      def source_present?
        !source.to_s.empty?
      end

      def path_valid?(path)
        !(path.to_s.include?('//') || path.to_s.include?('\\\\'))
      end
    end

    class << self
      def from_json(json)
        req = JSON.parse(json)

        res = RepositoryRequest.new(
          req['repository'], req['commit'], req['branch'])

        if req['folderOverride']
          req['folderOverride'].each do |fo|
            res.add_folder_override(fo['source'], fo['destinationOverride'])
          end
        end

        res
      end
    end

    attr_reader :repo, :commit_hash, :branch, :folder_override

    def initialize(repo, commit_hash, branch)
      @repo = repo ? repo.strip : nil
      @commit_hash = commit_hash ? commit_hash.downcase.strip : nil
      @branch = branch ? branch.strip : nil
      @folder_override = []
    end

    def add_folder_override(source, dest = nil)
      folder_override << FolderOverride.new(source, dest)
    end

    def submodules?
      folder_override.include?(FolderOverride.new('.gitmodules', nil))
    end

    def as_json
      repository_request_hash = {
        repository: repo,
        branch: branch,
        commit: commit_hash,
        folderOverride: nil
      }

      repository_request_hash[:folderOverride] =
        folder_override.map(&:as_json) unless folder_override.empty?

      repository_request_hash
    end

    def to_json(options = {})
      MultiJson.dump(as_json, options)
    end

    def valid?
      # rubocop:disable DoubleNegation
      !!(repo.try(:present?) && commit_hash.try(:present?) &&
        folder_override.all?(&:valid?))
      # rubocop:enable DoubleNegation
    end

    def errors
      errors = []
      errors << 'Repository is missing' unless repo
      errors << 'Commit hash is missing' unless commit_hash
      errors << folder_override.each_with_object([]) do |fo, s|
        s << { source: fo.source, dest: fo.destination, errors: fo.errors }
      end unless folder_override.empty?
      errors
    end

    def normalize!
      if folder_override.empty?
        add_folder_override(*PackageProvider.config.default_folder_override)
      end

      found_alias = RepositoryAlias.find(repo)
      @repo = found_alias ? found_alias.url : repo

      @repo.sub!(%r{\A(?!ssh://)(.*)@}, 'ssh://\1@')

      folder_override.map(&:normalize!)
      self
    end

    def checkout_mask
      folder_override.each_with_object([]) { |fo, s| s << fo.source }
    end

    def fingerprint
      @sha256 ||= Digest::SHA256.new
      h = { repository: repo,
            treeish: commit_hash,
            paths: checkout_mask,
            submodule: submodules? }

      @sha256.hexdigest h.to_json
    end

    def to_tsd
      result = "#{repo}|"
      result << "#{branch}:#{commit_hash}" if branch && commit_hash
      result << branch.to_s unless commit_hash
      result << commit_hash.to_s unless branch
      unless folder_override.empty?
        result << "(#{folder_override.map(&:to_tsd).join(',')})"
      end
      result
    end

    def ==(other)
      repo == other.repo &&
        commit_hash == other.commit_hash &&
        branch == other.branch &&
        folder_override == other.folder_override
    end
  end
end
