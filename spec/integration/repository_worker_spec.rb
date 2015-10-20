require 'sidekiq/testing'

describe 'Repository worker integration' do
  unless defined? ReposPool
    ReposPool = PackageProvider::RepositoryConnectionPool.new
  end

  let(:repository_worker) { PackageProvider::RepositoryWorker.new }
  let(:repo) do
    File.join(PackageProvider.root, 'spec', 'factories', 'testing-repo')
  end
  let(:req) do
    req = PackageProvider::RepositoryRequest.new(
      repo, '23e4306cc6e8fe5122f075be971e6155e00b5ad9', nil)

    req.add_folder_override('docs')
    req
  end

  after(:each) do
    dir = PackageProvider::CachedRepository.cache_dir(req)

    FileUtils.rm_rf(dir)
    FileUtils.rm_rf(dir + PackageProvider::CachedRepository::PACKAGE_PART_READY)
  end

  after(:all) do
    ReposPool.destroy
  end

  it 'prepares repository caches' do
    repository_worker.perform(req.to_json)

    dir = PackageProvider::CachedRepository.cache_dir(req)

    expect(Dir.exist?(dir)).to be true
    expect(Dir.exist?(File.join(dir, 'docs'))).to be true
  end
end
