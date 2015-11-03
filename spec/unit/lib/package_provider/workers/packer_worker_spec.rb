require 'sidekiq/testing'

describe PackageProvider::RepositoryConfig do
  let(:subject) { PackageProvider::PackerWorker.new }
  let(:request) do
    req = PackageProvider::PackageRequest.new
    req << PackageProvider::RepositoryRequest.new('repo', 'commit', nil)
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

      expect(subject).to receive(:reschedule)

      subject.perform(request.to_json)
    end

    it 'runs clone for missing repository' do
      allow(PackageProvider::CachedRepository)
        .to receive(:cached?) { false }

      Sidekiq::Testing.inline! do
        expect_any_instance_of(PackageProvider::RepositoryWorker)
          .to receive(:perform)

        expect(subject).to receive(:reschedule)

        subject.perform(request.to_json)
      end
    end
  end
end
