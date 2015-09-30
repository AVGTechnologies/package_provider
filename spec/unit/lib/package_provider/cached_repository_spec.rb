# required include pp because of superclass mismatch issue
# https://github.com/defunkt/fakefs/issues/99
require 'pp'
require 'fakefs/safe'

describe PackageProvider::CachedPackage do
  let(:fake_repo_url) { 'git_repository_url' }
  let(:subject) { PackageProvider::CachedRepository.new(fake_repo_url) }
  let(:request) { PackageProvider::RepositoryRequest.new('xx', 'treeish', nil) }
  let(:path) { PackageProvider::CachedRepository.cache_dir(request) }

  before(:all) do
    FakeFS.activate!
  end

  before(:each) do
    FileUtils.mkdir_p(path)

    expect_any_instance_of(PackageProvider::CachedRepository)
      .to receive(:init_repo!)
  end

  after(:each) do
    subject.destroy
  end

  after(:all) do
    FakeFS.deactivate!
  end

  describe '#cached_clone' do
    it 'raises error when repo url does not match with requested repo' do
      expect { subject.cached_clone(request) }.to raise_error(
        PackageProvider::CachedRepository::RepoServantDoesNotMatch)
    end
  end

  describe '::cached?' do
    it 'returns true if error occurs during clonning' do
      FileUtils.touch("#{path}.package_part_ready")
      FileUtils.touch("#{path}.error")

      expect(PackageProvider::CachedRepository.cached?(request))
        .to be true

      FileUtils.rm_rf("#{path}.error")
      FileUtils.rm_rf("#{path}.package_part_ready")
    end

    it 'returns true if repository cache is prepared' do
      FileUtils.touch("#{path}.package_part_ready")

      expect(PackageProvider::CachedRepository.cached?(request))
        .to be true

      FileUtils.rm_rf("#{path}.package_part_ready")
    end

    it 'returns false if clonning in progress' do
      FileUtils.touch("#{path}.clone_lock")

      expect(PackageProvider::CachedRepository.cached?(request))
        .to be false

      FileUtils.rm_rf("#{path}.clone_lock")
    end
  end
end
