require 'multi_json'

module PackageProvider
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
end
