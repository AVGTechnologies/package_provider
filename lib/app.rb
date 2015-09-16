$LOAD_PATH << 'lib'

require 'rack'
require 'rack/contrib'
require 'sinatra/base'
require 'sinatra/namespace'

require 'package_provider'
require 'package_provider/cached_repository'
require 'package_provider/package_packer'
require 'package_provider/repository_alias'
require 'package_provider/repository_request'
require 'package_provider/repository_config'
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
      repo_alias = PackageProvider::RepositoryAlias.find(params['alias'])
      unless repo_alias
        mes = "Couldn't find RepositoryAlias with alias=" \
              "#{params['alias'].inspect}"
        halt 404, { message: mes }.to_json
      end
      repo_alias.to_json
    end

    post '/package/download' do
      parser = PackageProvider::Parser.new
      package_request = parser.parse_json(request.body.read)

      package_request.normalize

      destination_dir = File.join(
        PackageProvider.config.package_cache_root, package_request.request_hash)

      send_file_if_exists(destination_dir)

      prepare_package(package_request, destination_dir)
    end
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

    private

    def send_file_if_exists(destination_dir)
      return unless Dir.exist?(destination_dir)
      send_file File.join(destination_dir, 'package.zip'),
                type: 'application/zip', status: 200
    end

    def prepare_package(reqs, destination_dir)
      FileUtils.mkdir_p(destination_dir)

      packer = PackageProvider::PackagePacker.new(destination_dir)

      reqs.each { |req| prepare_package_part(req, packer) }

      packer.flush
    end

    def prepare_package_part(req, packer)
      checkout_mask = req.folder_override.each_with_object([]) do |fo, s|
        s << fo.source
      end

      local_path = PackageProvider::RepositoryConfig.find(req.repo)[:cache_dir]

      repo = PackageProvider::CachedRepository.new(req.repo, local_path)
      checkout_dir = repo.cached_clone(
        req.commit_hash, checkout_mask, req.submodules?)
      repo.destroy

      req.folder_override.each do |fo|
        packer.add_folder(checkout_dir, fo)
      end
    end
  end

  # This makes the app launchanble like "ruby app.rb"
  run! if app_file == $PROGRAM_NAME
end
