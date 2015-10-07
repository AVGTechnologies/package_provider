require 'rack/test'
require 'sidekiq/testing'

describe 'Application API packages' do
  include Rack::Test::Methods

  def app
    PackageProvider::App.new
  end

  unless defined? ReposPool
    ReposPool = PackageProvider::RepositoryConnectionPool.new
  end

  describe 'packages API' do
    let(:headers_json) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
    end
    let(:headers_plain_text) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'text/plain'
      }
    end
    let(:headers_no_content_type) do
      {
        'HTTP_ACCEPT' => 'application/json'
      }
    end
    let(:prefix) { PackageProvider.config.base_url }
    let(:fake_repo_dir) do
      File.join(PackageProvider.root, 'spec', 'factories', 'testing-repo')
      # if ur developing with vagrant on windows machine you need to
      # copy test repo (spec/factories/test-repo) to your
      # file system ex. /tmp/testing-repo to git clone fix
      # just comment line 6 and uncomment line below
      # File.join('/var/tmp/factories', 'testing-repo')
    end

    after(:all) { ReposPool.destroy }

    it 'schedules package preparation with json request' do
      request = PackageProvider::PackageRequest.new
      request << PackageProvider::RepositoryRequest.new(
        'repo', 'treeish', nil)

      Sidekiq::Testing.inline! do
        expect_any_instance_of(PackageProvider::PackerWorker)
          .to receive(:perform)

        response = post(
          "#{prefix}/packages/download", request.to_json, headers_json)

        expect(response.status).to eq 202
      end
    end

    it 'schedules package preparation with text request' do
      request = 'package_provider|master:treeish'
      Sidekiq::Testing.inline! do
        expect_any_instance_of(PackageProvider::PackerWorker)
          .to receive(:perform)

        response = post(
          "#{prefix}/packages/download", request, headers_plain_text)

        expect(response.status).to eq 202
      end
    end

    it 'return error to unknown request' do
      response = post(
        "#{prefix}/packages/download", {}, headers_no_content_type)

      expect(response.status).to eq 400
    end

    it 'responds to unprepared package' do
      response = get "#{prefix}/packages/download/hash", {}, headers_json
      expect(response.status).to eq 202
    end

    it 'returns prepared package' do
      req = PackageProvider::RepositoryRequest.new(
        fake_repo_dir, '9191ed1ad760d66e84ef2e6fc24ea85e70404638', nil)
      req.add_folder_override('sources')

      request = PackageProvider::PackageRequest.new
      request << req

      path = PackageProvider::CachedPackage.package_path(request.fingerprint)
      FileUtils.mkdir_p(path)
      FileUtils.touch(File.join(path, 'package.zip'))
      FileUtils.touch(path + PackageProvider::CachedPackage::PACKAGE_READY)

      response = get(
        "#{prefix}/packages/download/#{request.fingerprint}", {}, headers_json)

      expect(response.status).to eq 200
      FileUtils.rm_rf(path)
      FileUtils.rm_rf(path + PackageProvider::CachedPackage::PACKAGE_READY)
    end

    it 'creates and returns package' do
      req = PackageProvider::RepositoryRequest.new(
        fake_repo_dir, '9191ed1ad760d66e84ef2e6fc24ea85e70404638', nil)
      req.add_folder_override('docs')

      request = PackageProvider::PackageRequest.new
      request << req

      Sidekiq::Testing.inline! do
        post("#{prefix}/packages/download", request.to_json, headers_json)
      end

      response = get(
        "#{prefix}/packages/download/#{request.fingerprint}", {}, headers_json)

      expect(response.content_length).to eq 240
      expect(response.status).to eq 200

      path = PackageProvider::CachedPackage.package_path(request.fingerprint)
      FileUtils.rm_rf(path)
      FileUtils.rm_rf(path + PackageProvider::CachedPackage::PACKAGE_READY)
      repo_path = PackageProvider::CachedRepository.cache_dir(req)
      FileUtils.rm_rf(repo_path)
      FileUtils.rm_rf(
        repo_path + PackageProvider::CachedRepository::PACKAGE_PART_READY)
    end

    context 'request processing' do
      context 'application/json' do
        context 'something is missing in request' do
          it 'misses repository' do
            req = PackageProvider::RepositoryRequest.new(
              nil, 'commit_hash', 'branch')

            response = post(
              "#{prefix}/packages/download", [req].to_json, headers_json)
            expect(response.status).to eq 400
          end

          it 'misses branch and commit hash' do
            req = PackageProvider::RepositoryRequest.new('repo', nil, nil)

            response = post(
              "#{prefix}/packages/download", [req].to_json, headers_json)

            expect(response.status).to eq 400
          end

          it 'misses source in folder override' do
            req = PackageProvider::RepositoryRequest.new(
              'repo', 'commit_hash', 'branch')
            req.add_folder_override(nil)

            response = post(
              "#{prefix}/packages/download", [req].to_json, headers_json)

            expect(response.status).to eq 400
          end

          it 'misses commit hash' do
            req = PackageProvider::RepositoryRequest.new('repo', nil, 'branch')

            response = post(
              "#{prefix}/packages/download", [req].to_json, headers_json)

            expect(response.status).to eq 400
          end
        end

        it 'returns HTTP status 400 to unparsable json' do
          response = post(
            "#{prefix}/packages/download", { invalid: 'json' }, headers_json)

          expect(response.status).to eq 400
        end

        it 'returns HTTP status 400 to bad request' do
          response = post(
            "#{prefix}/packages/download",
            { repo: 'repo' }.to_json,
            headers_json)

          expect(response.status).to eq 400
        end
      end
      context 'text/plain' do
        context 'something is missing in request' do
          it 'misses source in folder override' do
            req = 'repo|branch:commit_hash(>dest)'

            response = post(
              "#{prefix}/packages/download", req, headers_plain_text)

            expect(response.status).to eq 400
          end

          it 'misses commit hash' do
            req = 'repo|branch'

            response = post(
              "#{prefix}/packages/download", req, headers_plain_text)

            expect(response.status).to eq 400
          end
        end
      end
    end
  end
end
