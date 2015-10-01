require 'rack/test'
require 'pp'
require 'fakefs/safe'

describe 'Application API repositories' do
  include Rack::Test::Methods

  def app
    PackageProvider::App.new
  end

  describe 'repositories API' do
    let(:headers_json) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
    end
    let(:prefix) { PackageProvider.config.base_url }

    path = File.join(PackageProvider.root, 'config')

    before(:all) do
      FakeFS.activate!
    end

    before(:each) do
      FileUtils.mkdir_p(path)
      File.open("#{path}/repository_aliases.yml", 'w+') do |f|
        f.puts YAML.dump(
          test: { aliases: { fake_alias: 'git://example.com/' } })
      end
      PackageProvider::RepositoryAlias.reload!
    end

    after(:all) do
      FakeFS.deactivate!
      PackageProvider::RepositoryAlias.reload!
    end

    it 'reloads alias list' do
      get "#{prefix}repositories/new_alias", {}, headers_json
      expect(last_response.status).to eq 404

      File.open("#{path}/repository_aliases.yml", 'w+') do |f|
        f.puts YAML.dump(
          test: { aliases: { new_alias: 'git://example.com/' } })
      end

      response = post '/api/v1/repositories/reload', {}, headers_json
      expect(response.status).to eq 200

      get '/api/v1/repositories/new_alias', {}, headers_json
      expect(last_response.status).to eq 200
    end

    it 'gets all repositories aliases' do
      response = get "#{prefix}/repositories", {}, headers_json
      expect(response.body).to eq PackageProvider::RepositoryAlias.all.to_json
    end

    it 'returns existing repository alias' do
      response = get "#{prefix}/repositories/fake_alias", {}, headers_json
      expect(response.body).to eq(
        PackageProvider::RepositoryAlias.find('fake_alias').to_json)
    end

    it 'non existing repository alias' do
      response = get(
        "#{prefix}/repositories/non_existing_alias", {}, headers_json)

      expect(response.status).to eq 404
    end
  end
end
