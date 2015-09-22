describe 'Cached repository integration' do
  let(:fake_remote_repo_dir) do
    File.join(PackageProvider.root, 'spec', 'factories', 'testing-repo')
    # if ur developing with vagrant on windows machine you need to
    # copy test repo (spec/factories/test-repo) to your
    # file system ex. /tmp/testing-repo to git clone fix
    # just comment line 6 and uncomment line below
    # File.join('/var/tmp/factories', 'testing-repo')
  end
  let(:repo) { PackageProvider::CachedRepository.new(fake_remote_repo_dir) }
  let(:repo2) { PackageProvider::CachedRepository.new(fake_remote_repo_dir) }
  let(:paths) { ['docs/**'] }
  let(:dir) do
    PackageProvider::CachedRepository.cache_dir(commit_hash, paths, false)
  end
  let(:commit_hash) { '9191ed1ad760d66e84ef2e6fc24ea85e70404638' }

  after(:each) do
    repo && repo.destroy
  end

  describe '#cached_clone' do
    after(:each) do
      FileUtils.rm_rf(dir)
      FileUtils.rm_rf("#{dir}.package_part_ready")
    end

    it 'creates cache' do
      repo.cached_clone(commit_hash, paths)

      expect(Dir.exist?(dir)).to be true
      expect(File.exist?("#{dir}.package_part_ready")).to be true
      expect(File.exist?("#{dir}.clone_lock")).to be false
    end

    it 'loads from existing cache' do
      repo.cached_clone(commit_hash, paths)

      expect(repo).not_to receive(:clone).with(any_args)

      repo.cached_clone(commit_hash, paths)
    end

    it 'handles multiple same requests at once' do
      thread_ready = false
      t = Thread.new do
        expect(repo).to receive(:clone).with(any_args) do
          thread_ready = true
          Thread.pass
          sleep 3
        end
        repo.cached_clone(commit_hash, paths)
      end

      Thread.pass until thread_ready

      expect { repo2.cached_clone(commit_hash, paths) }.to raise_error(
        PackageProvider::CachedRepository::CloneInProgress)
      t.join
    end

    it 'removes .clone_lock file on Exception' do
      expect(repo).to receive(:clone).with(any_args) { fail RuntimeError }

      expect { repo.cached_clone(commit_hash, paths) }.to raise_error(
        RuntimeError)

      expect(File.exist?("#{dir}.package_part_ready")).to be false
      expect(File.exist?("#{dir}.clone_lock")).to be false
    end
  end
end
