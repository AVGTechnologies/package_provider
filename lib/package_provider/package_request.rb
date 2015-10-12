module PackageProvider
  # Class for containing whole package request
  class PackageRequest < Array
    def normalize!
      map(&:normalize!)
    end

    def fingerprint
      sha = Digest::SHA256.new
      sha.hexdigest normalize!.to_json
    end

    def to_tsd
      map(&:to_tsd).join(',')
    end

    def valid?
      all?(&:valid?)
    end

    def errors
      each_with_object([]) do |req, s|
        s << { request: req.to_tsd, errors: req.errors } unless req.valid?
      end
    end
  end
end
