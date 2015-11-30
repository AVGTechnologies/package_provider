require 'sidekiq/testing'
require 'sidekiq_unique_jobs/testing'

describe PackageProvider::PackerWorker do
  let(:subject) { PackageProvider::PackerWorker.new }
  let(:request) do
    req = PackageProvider::PackageRequest.new
    req << PackageProvider::RepositoryRequest.new('repo', 'commit', nil)
  end

  before(:each) do
    Sidekiq::Worker.clear_all
  end

  describe '#perform' do
    it 'packs package if all repositories are ready' do
      allow(PackageProvider::CachedRepository)
        .to receive(:cached?) { true }

      expect_any_instance_of(PackageProvider::CachedPackage)
        .to receive(:cache_package)

      subject.perform(request.to_json)
    end
    it 'reschedules if one of repository cache is missing' do
      allow(PackageProvider::CachedRepository)
        .to receive(:cached?) { false }

      allow(PackageProvider::RepositoryWorker).to receive(:perform_async)
      expect(subject).to receive(:reschedule)

      subject.perform(request.to_json)
    end

    it 'runs clone for missing repository' do
      allow(PackageProvider::CachedRepository)
        .to receive(:cached?) { false }

      Sidekiq::Testing.inline! do
        expect(PackageProvider::RepositoryWorker).to receive(:perform_async)
        allow(subject).to receive(:reschedule)

        subject.perform(request.to_json)
      end
    end
    it 'doesn\'t runs clone for scheduled repository' do
      allow(PackageProvider::CachedRepository)
        .to receive(:cached?) { false }

      Sidekiq::Testing.fake! do
        expect do
          subject.perform(request.to_json)
          subject.perform(request.to_json)
        end.to change(PackageProvider::RepositoryWorker.jobs, :size).by(1)
      end
    end
  end
end
