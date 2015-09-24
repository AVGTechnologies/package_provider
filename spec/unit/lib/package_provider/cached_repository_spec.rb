describe PackageProvider::CachedPackage do
  let(:fake_repo_url) { 'git_repository_url' }
  let(:subject) { PackageProvider::CachedRepository.new(fake_repo_url) }
  let(:request) { PackageProvider::RepositoryRequest.new('xx', 'treeish', nil) }

  before(:each) do
    expect_any_instance_of(PackageProvider::CachedRepository)
      .to receive(:init_repo!)
  end

  after(:each) do
    subject.destroy
  end
  
  describe '#cached_clone' do
    it 'raises error when repo url does not match with requested repo' do
      expect { subject.cached_clone(request) }.to raise_error(
        PackageProvider::CachedRepository::RepoServantDoesNotMatch)
    end
  end
end
