require 'package_provider/package_request'
require 'package_provider/repository_request'

module PackageProvider
  # Class for parsing package requests
  class Parser
    class ParsingError < ArgumentError
    end

    def logger
      PackageProvider.logger
    end

    def parse(request)
      parts = tsd_request2parts(request)
      fail ParsingError, 'nothing to process' if parts.empty?

      parts.inject(PackageRequest.new) do |s, package_part|
        repo, source_and_folder_override = check_part(package_part)

        if source_and_folder_override.sub!(/\((.*)\)$/, '')
          folder_override = Regexp.last_match[1]
        end

        src_branch, src_commit_hash = get_branch_and_commit_hash(source_and_folder_override)

        resp = RepositoryRequest.new(repo, src_commit_hash, src_branch)

        folder_override.to_s.split(',').map do |fo|
          value = fo.split(/\s*>\s*/, 2)
          resp.add_folder_override(*value)
        end

        s << resp
      end
    end

    def parse_json(request)
      JSON.parse(request).inject(PackageRequest.new) do |s, req|
        s << RepositoryRequest.from_json(req.to_json)
      end
    end

    private

    def replace_commas(request)
      nested_level = 0

      request.each_char.with_index do |c, i|
        case c
        when '('
          nested_level += 1
        when ')'
          nested_level -= 1
        when ','
          request[i] = ';' if nested_level == 0
        end
      end

      request
    end

    def tsd_request2parts(request)
      unless request.count('(') == request.count(')')
        fail ParsingError, 'Incorect parenthness'
      end

      request = replace_commas(request)
      splitted_parts = request.split(';')

      splitted_parts.map!(&:strip)
    end

    def valid_commit_hash_format?(commit_hash)
      commit_hash.downcase =~ /\A[0-9a-f]{40}\z/
    end

    def get_branch_and_commit_hash(branch_and_commit_hash)
      src_branch, src_commit_hash = branch_and_commit_hash.split(':', 2)

      if src_commit_hash.nil? && valid_commit_hash_format?(src_branch)
        src_commit_hash = src_branch
        src_branch = nil
      end

      [src_branch, src_commit_hash]
    end

    def check_part(package_part)
      fail ParsingError, '| is missing' unless package_part.include?('|')

      repo, source_and_folder_override = package_part.split('|', 2)

      if source_and_folder_override.to_s.empty?
        fail ParsingError, 'Source specification is missing'
      end

      [repo, source_and_folder_override]
    end
  end
end
