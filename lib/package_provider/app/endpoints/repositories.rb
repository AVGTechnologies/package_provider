require 'package_provider/app/endpoints/base'
require 'package_provider/repository_alias'

module PackageProvider
  class App
    module Endpoints
      # handles all endpoints related to Aliases
      class Repositories < Base
        get '/' do
          PackageProvider::RepositoryAlias.all.to_json
        end

        post '/reload' do
          PackageProvider::RepositoryAlias.reload!
          halt 200
        end

        get '/:alias' do
          repo_alias = PackageProvider::RepositoryAlias.find(params['alias'])
          unless repo_alias
            mes = "Couldn't find RepositoryAlias with alias=" \
                  "#{params['alias'].inspect}"
            halt 404, { message: mes }.to_json
          end
          repo_alias.to_json
        end
      end
    end
  end
end
