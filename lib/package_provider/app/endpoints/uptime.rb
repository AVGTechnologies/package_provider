require 'package_provider/app/endpoints/base'

module PackageProvider
  class App
    module Endpoints
      # handles uptime endpoint
      class Uptime < Base
        get '/uptime' do
          "Ready and waiting from #{PackageProvider.start_time}!"
        end
      end
    end
  end
end
