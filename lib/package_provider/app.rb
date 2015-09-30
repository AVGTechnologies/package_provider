$LOAD_PATH << 'lib'
require 'rack'
require 'rack/showexceptions'

require 'package_provider'
require 'package_provider/app/endpoints/uptime'
require 'package_provider/app/endpoints/repositories'
require 'package_provider/app/endpoints/packages'

PackageProvider.setup

module PackageProvider
  # base rest service class
  class App
    attr_reader :app

    def initialize
      @app = Rack::Builder.app do
        use Raven::Rack
        use Rack::ShowExceptions unless PackageProvider.env == 'production'

        map PackageProvider.config.base_url do
          map '/' do
            run PackageProvider::App::Endpoints::Uptime.new
          end

          map '/repositories' do
            run PackageProvider::App::Endpoints::Repositories.new
          end

          map '/packages' do
            run PackageProvider::App::Endpoints::Packages.new
          end
        end
      end
    end

    def call(env)
      app.call(env)
    end
  end
end
