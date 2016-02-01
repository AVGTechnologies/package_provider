require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

describe PackageProvider::PackerWorker do
  let(:package_hash) { 'abc' }
  let(:subject) { PackageProvider::PackerWorker.new }
  let(:package_request) do
    req = PackageProvider::PackageRequest.new
    req << PackageProvider::RepositoryRequest.new('repo', 'commit', nil)
  end
  let(:repository_request) do
    PackageProvider::RepositoryRequest.new('repo', nil, 'branch')
  end
  let(:package_request_without_commit_hash) do
    req = PackageProvider::PackageRequest.new
    req << repository_request
  end

  before(:each) do
    Sidekiq::Worker.clear_all
  end

  describe '#perform' do
    it 'packs package if all repositories are ready' do
      allow(PackageProvider::CachedRepository).to receive(:cached?) { true }

      expect_any_instance_of(PackageProvider::CachedPackage).to receive(:cache_package)

      subject.perform(package_hash, package_request.to_json)
    end

    it 'reschedules if one of repository cache is missing' do
      allow(PackageProvider::CachedRepository).to receive(:cached?) { false }
      allow(PackageProvider::RepositoryWorker).to receive(:perform_async)

      expect(subject).to receive(:reschedule)

      subject.perform(package_hash, package_request.to_json)
    end

    it 'runs clone for missing repository' do
      allow(PackageProvider::CachedRepository).to receive(:cached?) { false }

      Sidekiq::Testing.inline! do
        allow(subject).to receive(:reschedule)

        expect(PackageProvider::RepositoryWorker).to receive(:perform_async)

        subject.perform(package_hash, package_request.to_json)
      end
    end

    it 'doesn\'t run clone for scheduled repository' do
      allow(PackageProvider::CachedRepository).to receive(:cached?) { false }

      Sidekiq::Testing.fake! do
        expect do
          subject.perform(package_hash, package_request.to_json)
          subject.perform(package_hash, package_request.to_json)
        end.to change(PackageProvider::RepositoryWorker.jobs, :size).by(1)
      end
    end

    it 'resolves missing commit hash' do
      Sidekiq::Testing.inline! do
        expect(PackageProvider::Repository).to receive(:commit_hash) { 'commit_hash' }

        allow(PackageProvider::RepositoryWorker).to receive(:perform_async)
        allow(subject).to receive(:reschedule)

        subject.perform(package_hash, package_request_without_commit_hash.to_json)
      end
    end

    it 'marks repo as errored when commit hash fails to resolve' do
      Sidekiq::Testing.inline! do
        expect(PackageProvider::Repository).to receive(:commit_hash) do
          fail PackageProvider::Repository::GitError, 'Fake error'
        end

        allow_any_instance_of(PackageProvider::CachedPackage).to receive(:cache_package)

        subject.perform(package_hash, package_request_without_commit_hash.to_json)
      end

      dir = PackageProvider::CachedRepository.cache_dir(repository_request)

      expect(File.exist?(dir + PackageProvider::CachedRepository::ERROR)).to be true

      FileUtils.rm_rf(dir)
      FileUtils.rm_rf(dir + PackageProvider::CachedRepository::ERROR)
      FileUtils.rm_rf(dir + PackageProvider::CachedRepository::PACKAGE_PART_READY)
    end
  end
end
