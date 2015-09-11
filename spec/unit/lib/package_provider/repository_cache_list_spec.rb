describe PackageProvider::RepositoryCacheList do
  path = File.join(PackageProvider.root, 'config')
  repo_url = 'git@github.com:AVGTechnologies/package_provider.git'

  before(:all) do
    FakeFS.activate!

    FileUtils.mkdir_p(path)
    File.open("#{path}/repository_cache.yml", 'w+') do |f|
      f.puts YAML.dump(
        test: { local_repo_paths: { repo_url => path } })
    end
  end

  after(:all) do
    FakeFS.deactivate!
  end

  let(:subject) { PackageProvider::PackagePacker.new(package_path) }

  describe '::find' do
    it 'returns local path for git repo url' do
      expect(PackageProvider::RepositoryCacheList.find(repo_url)).to eq(path)
    end
    it 'return nil for unknown repo url' do
      expect(PackageProvider::RepositoryCacheList.find('repo_url')).to be nil
    end
  end
end
