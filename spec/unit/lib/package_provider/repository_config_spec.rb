# required include pp because of superclass mismatch issue
# https://github.com/defunkt/fakefs/issues/99
require 'pp'
require 'fakefs/safe'

describe PackageProvider::RepositoryConfig do
  path = File.join(PackageProvider.root, 'config')
  repo_url = 'git@github.com:AVGTechnologies/package_provider.git'

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

  describe '::find' do
    it 'returns local path for git repo url' do
      expect(PackageProvider::RepositoryConfig.find(repo_url)[:cache_dir])
        .to eq(path)
    end
    it 'returns nil for unknown repo url' do
      expect(PackageProvider::RepositoryConfig.find('repo_url')[:cache_dir])
        .to be nil
    end
    it 'uses configed value' do
      expect(PackageProvider::RepositoryConfig.find(repo_url)[:timeout])
        .to eq(2)
    end
    it 'uses default value from config when property not defined' do
      expect(PackageProvider::RepositoryConfig.find(repo_url)[:pool_size])
        .to eq(1)
    end
  end
end
