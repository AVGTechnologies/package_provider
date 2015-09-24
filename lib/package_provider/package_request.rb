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
  end
end
