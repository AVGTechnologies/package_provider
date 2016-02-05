require 'sidekiq/testing'
require 'package_provider/repository_connection_pool'
require 'zip'

describe 'Packer worker integration' do
  unless defined? ReposPool
    ReposPool = PackageProvider::RepositoryConnectionPool.new
  end

  let(:packer_worker) { PackageProvider::PackerWorker.new }
  let(:package_hash) { 'abc' }
  let(:repo) { File.join(PackageProvider.root, 'spec', 'factories', 'testing-repo') }
  let(:request_with_docs_folder) do
    req = PackageProvider::RepositoryRequest.new(
      repo, '23e4306cc6e8fe5122f075be971e6155e00b5ad9', nil)
    req.add_folder_override('docs')

    req
  end
  let(:request_with_sources_folder) do
    req = PackageProvider::RepositoryRequest.new(
      repo, '23e4306cc6e8fe5122f075be971e6155e00b5ad9', nil)
    req.add_folder_override('sources')

    req
  end
  let(:request_without_commit_hash) do
    req = PackageProvider::RepositoryRequest.new(repo, nil, 'master')
    req.add_folder_override('sources')
    req
  end
  let(:package_request) do
    package_request = PackageProvider::PackageRequest.new
    package_request << request_with_docs_folder
    package_request << request_with_sources_folder
    package_request
  end
  let(:package_request_without_commit_hash) do
    package_request = PackageProvider::PackageRequest.new
    package_request << request_without_commit_hash
    package_request
  end

  after(:each) do
    request_without_commit_hash.commit_hash = '23e4306cc6e8fe5122f075be971e6155e00b5ad9'

    to_delete = [
      request_with_docs_folder,
      request_with_sources_folder,
      request_without_commit_hash
    ]

    to_delete.each do |req|
      dir = PackageProvider::CachedRepository.cache_dir(req)
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(dir + PackageProvider::CachedRepository::PACKAGE_PART_READY)
    end

    package_dir = PackageProvider::CachedPackage.package_directory(package_hash)

    FileUtils.rm_rf(package_dir)
    FileUtils.rm_rf(package_dir + PackageProvider::CachedPackage::PACKAGE_READY)
  end

  after(:all) do
    ReposPool.destroy
  end

  it 'packs package' do
    Sidekiq::Testing.inline! do
      packer_worker.perform(package_hash, package_request.to_json)
    end

    path = PackageProvider::CachedPackage.from_cache(package_hash)

    expect(File.exist?(path)).to be true

    zip_file = Zip::File.open(path)

    expect(zip_file.read('doc1.txt')).not_to be nil
    expect(zip_file.read('source1.txt')).not_to be nil
  end

  it 'resolves commit hash' do
    Sidekiq::Testing.inline! do
      packer_worker.perform(package_hash, package_request_without_commit_hash.to_json)
    end

    path = PackageProvider::CachedPackage.from_cache(package_hash)

    expect(File.exist?(path)).to be true
  end
end
