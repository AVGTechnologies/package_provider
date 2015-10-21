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

  describe '#fetch' do
    before(:all) do
      FakeFS.activate!

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
  end
end
