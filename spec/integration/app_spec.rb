require 'rack/test'
require 'pp'
require 'fakefs/safe'

describe 'Application API' do
  include Rack::Test::Methods

  def app
    PackageProvider::App.new
  end

  describe 'API' do
    let(:headers) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
    end
    let(:request) do
      PackageProvider::RepositoryRequest.new(
        'repo', 'commit', nil)
    end
    let(:prefix) { PackageProvider.config.base_url }

    it 'responds to uptime' do
      response = get "#{prefix}/uptime", {}, headers
      expect(response.body).to eq(
        "Ready and waiting from #{PackageProvider.start_time}!")
    end

    context 'repositories' do
      path  = File.join(PackageProvider.root, 'config')

      before(:each) do
        FakeFS.activate!

        FileUtils.mkdir_p(path)
        File.open("#{path}/repository_aliases.yml", 'w+') do |f|
          f.puts YAML.dump(
            test: { aliases: { fake_alias: 'git://example.com/' } })
        end
        PackageProvider::RepositoryAlias.reload!
      end

      after(:each) do
        FakeFS.deactivate!
      end

      after(:all) do
        PackageProvider::RepositoryAlias.reload!
      end

      it 'reloads alias list' do
        get "#{prefix}repositories/new_alias", {}, headers
        expect(last_response.status).to eq 404

        File.open("#{path}/repository_aliases.yml", 'w+') do |f|
          f.puts YAML.dump(
            test: { aliases: { new_alias: 'git://example.com/' } })
        end

        response = post '/api/v1/repositories/reload', {}, headers
        expect(response.status).to eq 200

        get '/api/v1/repositories/new_alias', {}, headers
        expect(last_response.status).to eq 200
      end

      it 'gets all repositories aliases' do
        response = get "#{prefix}/repositories", {}, headers
        expect(response.body).to eq PackageProvider::RepositoryAlias.all.to_json
      end

      it 'returns existing repository alias' do
        response = get "#{prefix}/repositories/fake_alias", {}, headers
        expect(response.body).to eq(
          PackageProvider::RepositoryAlias.find('fake_alias').to_json)
      end

      it 'non existing repository alias' do
        response = get "#{prefix}/repositories/non_existing_alias", {}, headers
        expect(response.status).to eq 404
      end
    end

    context 'package' do
      it 'schedules package preparation with json request'

      it 'schedules package preparation with text request'

      it 'responds to unprepared package' do
        response = get "#{prefix}/packages/download/hash", {}, headers
        expect(response.status).to eq 202
      end

      it 'returns prepared package'
    end
  end
end
