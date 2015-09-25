require 'multi_json'
require 'sinatra/base'

require 'package_provider/app/helpers/error_handling'

module PackageProvider
  class App
    module Endpoints
      # base REST api service class
      class Base < Sinatra::Base
        set :protection, origin_whitelist: PackageProvider.config.allowed_origin

        register ErrorHandling

        before do
          response['Access-Control-Allow-Origin'] =
            PackageProvider.config.allowed_origin
        end

        # CORS
        options '*' do
          response.headers['Access-Control-Allow-Methods'] =
            'HEAD, GET, PUT, POST, DELETE, OPTIONS'
          # Needed for AngularJS
          response.headers['Access-Control-Allow-Headers'] =
            'X-Requested-With, X-HTTP-Method-Override, Content-Type, ' \
            'Cache-Control, Accept'
          halt 200
        end

        after { content_type(:json) unless content_type }

        configure :development do
          enable :dump_errors
        end
      end
    end
  end
end
