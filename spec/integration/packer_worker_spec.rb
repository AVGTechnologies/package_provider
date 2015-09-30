require 'sidekiq/testing'
require 'package_provider/repository_connection_pool'
require 'zip'

describe 'Packer worker integration' do
  unless defined? ReposPool
    ReposPool = PackageProvider::RepositoryConnectionPool.new
  end

  let(:packer_worker) { PackageProvider::PackerWorker.new }
  let(:repo) do
    File.join(PackageProvider.root, 'spec', 'factories', 'testing-repo')
  end
  let(:req) do
    req = PackageProvider::RepositoryRequest.new(
      repo, '23e4306cc6e8fe5122f075be971e6155e00b5ad9', nil)

    req.add_folder_override('docs')
    req
  end
  let(:req2) do
    req = PackageProvider::RepositoryRequest.new(
      repo, '23e4306cc6e8fe5122f075be971e6155e00b5ad9', nil)

    req.add_folder_override('sources')
    req
  end
  let(:package_request) do
    package_request = PackageProvider::PackageRequest.new
    package_request << req
    package_request << req2
    package_request
  end

  after(:each) do
    dir = PackageProvider::CachedRepository.cache_dir(req)
    dir2 = PackageProvider::CachedRepository.cache_dir(req2)

    package_dir = PackageProvider::CachedPackage.package_path(
      package_request.fingerprint)

    FileUtils.rm_rf(dir)
    FileUtils.rm_rf("#{dir}.package_part_ready")

    FileUtils.rm_rf(dir2)
    FileUtils.rm_rf("#{dir2}.package_part_ready")

    FileUtils.rm_rf(package_dir)
    FileUtils.rm_rf("#{package_dir}.package_ready")
  end

  after(:all) do
    ReposPool.destroy
  end

  it 'packs package' do
    Sidekiq::Testing.inline! do
      packer_worker.perform(package_request.to_json)
    end

    path = PackageProvider::CachedPackage.from_cache(
      package_request.fingerprint)

    expect(File.exist?(path)).to be true

    zip_file = Zip::File.open(path)
    expect(zip_file.read('docs/doc1.txt')).not_to be nil
    expect(zip_file.read('sources/source1.txt')).not_to be nil
  end
end
