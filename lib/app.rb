# Service providing the package provider functionality

$LOAD_PATH << 'lib'
require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require 'sinatra/namespace'

require 'package_provider'
require 'package_provider/repository_alias'
require 'package_provider/repository_request'
require 'package_provider/request_parser/parser'

require 'app/helpers/error_handling'

PackageProvider.setup

# main application class
class App < Sinatra::Base
  set :bind, PackageProvider.config.bind
  set :protection, origin_whitelist: PackageProvider.config.allowed_origin
  set :show_exceptions, PackageProvider.config.show_exceptions

  register Sinatra::Namespace
  register ErrorHandling

  before do
    response['Access-Control-Allow-Origin'] =
      PackageProvider.config.allowed_origin
  end

  after { content_type(:json) unless content_type }

  options '*' do
    response.headers['Access-Control-Allow-Methods'] =
      'HEAD, GET, PUT, POST, DELETE, OPTIONS'
    # Needed for AngularJS
    response.headers['Access-Control-Allow-Headers'] =
      'X-Requested-With, X-HTTP-Method-Override, Content-Type, ' \
      'Cache-Control, Accept'
    halt 200
  end

  get '/uptime' do
    "Ready and waiting from #{PackageProvider.start_time}!"
  end

  namespace PackageProvider.config.base_url do
    get '/repositories' do
      PackageProvider::RepositoryAlias.all.to_json
    end

    post '/repositories/reload' do
      PackageProvider::RepositoryAlias.reload!
      halt 200
    end

    get '/repositories/:alias' do
      PackageProvider::RepositoryAlias.find(params['alias']).to_json
    end

    post '/package/download' do
      parser = PackageProvider::Parser.new
      reqs = parser.parse_json(request.body.read)
      reqs.to_json
=begin
      result = Packer.get_from_cache(request)
      halt 200, result if result

      needs_clone_repo = false
      reqs.each do |req|
        next if Repo.is_clonned?(req[:repo], req[:paths], res[:sumbodules])
        needs_clone_repo = true
        RepoWorker.perform_async(req[:repo], req[:paths], res[:sumbodules])
      end
      if needs_clone_repo
        PackkerWorker.perform_async(res, in: 10)
        halt 204
      end

      PackkerWorker.perform_async(res)
      halt 204
=end
    end
  end

  # This makes the app launchanble like "ruby app.rb"
  run! if app_file == $PROGRAM_NAME
end
