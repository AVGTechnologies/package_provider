require 'securerandom'
require 'package_provider/app/endpoints/base'
require 'package_provider/request_parser/parser'
require 'package_provider/cached_package'
require 'package_provider/workers/packer_worker'

module PackageProvider
  class App
    module Endpoints
      # handles all endpoints related to packages
      class Packages < Base
        post '/download' do
          package_request = parse_request(request)
          halt 400, { message: 'Unknown format' }.to_json unless package_request

          halt 400, package_request.errors.to_json unless package_request.valid?

          package_request.normalize!
          package_hash = SecureRandom.uuid

          PackageProvider::PackerWorker.perform_async(package_hash, package_request.to_json)

          halt 202, { package_hash: "#{package_hash}" }.to_json
        end

        get '/download/:package_hash' do
          info = PackageProvider::CachedPackage.errors(params['package_hash'])
          halt 422, info if info

          result = PackageProvider::CachedPackage.from_cache(params['package_hash'])
          if result
            Metriks.meter('packageprovider.package.downloaded').mark
            return send_file(result, type: 'application/zip')
          end

          halt 204
        end

        def parse_request(request)
          if request.media_type == 'application/json'
            return PackageProvider::Parser.new.parse_json(request.body.read)
          elsif request.media_type == 'text/plain'
            return PackageProvider::Parser.new.parse(request.body.read)
          end
        rescue => err
          halt 400,
               { message: 'Unable to process request.', error: err }.to_json
        end
      end
    end
  end
end
