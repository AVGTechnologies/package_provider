# required include pp because of superclass mismatch issue
# https://github.com/defunkt/fakefs/issues/99
require 'pp'
require 'fakefs/safe'

describe PackageProvider::RepositoryConnectionPool do
  path = File.join(PackageProvider.root, 'config')
  repo_url = 'git@github.com:AVGTechnologies/package_provider.git'

  let(:subject) { PackageProvider::RepositoryConnectionPool.new }
  let(:request) do
    PackageProvider::RepositoryRequest.new(repo_url, nil, 'fake_branch')
  end
  let(:malformed_request) do
    PackageProvider::RepositoryRequest.new('not_a_git_repo', nil, 'fake_branch')
  end

  describe '#fetch' do
    before(:all) do
      FakeFS.activate!

      FileUtils.mkdir_p(PackageProvider.config.repository_cache_root)
      FileUtils.mkdir_p(path)
      File.open("#{path}/repository_config.yml", 'w+') do |f|
        f.puts YAML.dump(
          test: { repositories: { repo_url => { cache_dir: path, timeout: 2 } },
                  defaults:     { timeout: 1, pool_size: 1 }
                })
      end
    end

    after(:all) do
      FakeFS.deactivate!
    end

    it 'returns same instance of ConnectionPool for same repository request' do
      repo = subject.fetch(request)
      repo2 = subject.fetch(request)

      expect(repo).to eq(repo2)
    end

    it 'returns instance of ConnectionPool' do
      repo = subject.fetch(request)

      expect(repo).to be_an_instance_of(ConnectionPool)
    end

    it 'create error and package_part_ready files on Clone error' do
      c_pool = subject.fetch(malformed_request)

      status = double(:status)
      expect(status).to receive(:success?).twice.and_return(false)
      expect(Open3).to(
        receive(:capture3)
        .with({ 'ENV' => PackageProvider.env }, /.*init_repo.sh/, any_args)
        .once
        .and_return(['', '', status])
      )

      expect { c_pool.with { nil } }
        .to raise_error(PackageProvider::Repository::CannotInitRepo)

      expect(File.exist?(error_path(malformed_request))).to be true
      expect(File.exist?(package_part_ready_path(malformed_request)))
        .to be true
    end

    it 'create error and package_part_ready files on general error' do
      c_pool = subject.fetch(malformed_request)

      expect(Open3).to receive(:capture3).with(any_args) do
        fail StandardError
      end

      expect { c_pool.with { nil } }.to raise_error(StandardError)

      expect(File.exist?(error_path(malformed_request))).to be true
      expect(File.exist?(package_part_ready_path(malformed_request)))
        .to be true
    end

    def error_path(request)
      PackageProvider::CachedRepository.cache_dir(request) +
        PackageProvider::CachedRepository::ERROR
    end

    def package_part_ready_path(request)
      PackageProvider::CachedRepository.cache_dir(request) +
        PackageProvider::CachedRepository::PACKAGE_PART_READY
    end
  end
end
