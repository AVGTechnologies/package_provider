# required include pp because of superclass mismatch issue
# https://github.com/defunkt/fakefs/issues/99
require 'pp'
require 'fakefs/safe'

describe PackageProvider::Repository do
  PackageProvider::Repository.temp_prefix = "pp_tests_#{rand(1000)}"

  let(:repo) do
    PackageProvider::Repository.new(
      'https://github.com/AVGTechnologies/package_provider')
  end

  let(:repo2) do
    PackageProvider::Repository.new(
      'git@github.com:ondrej-hosak/package_provider.git')
  end

  let(:repo3) do
    PackageProvider::Repository.new(
      'https://ondrej.hosak@stash.megacorp.com/scm/xxx/package_provider.git')
  end

  let(:repo4) do
    PackageProvider::Repository.new(
      'ssh://git@stash.megacorp.com:8085/xxx/package_provider.git')
  end

  let(:repo5) do
    PackageProvider::Repository.new(
      '/tmp/package_provider')
  end

  let(:repo6) do
    PackageProvider::Repository.new(
      '/package_provider')
  end

  let(:request) do
    PackageProvider::RepositoryRequest.new('test', nil, 'branch')
  end

  let(:request_with_nil_branch) do
    PackageProvider::RepositoryRequest.new('test', nil, nil)
  end

  let(:request_with_wrong_branch) do
    PackageProvider::RepositoryRequest.new('test', nil, 'non-existing')
  end

  let(:request_with_wrong_repo) do
    PackageProvider::RepositoryRequest.new('test', nil, 'non-existing')
  end

  before(:all) do
    FakeFS.activate!
  end

  before(:each) do |example|
    unless example.metadata[:skip_hook]
      status = double(:status)
      expect(status).to receive(:success?).twice.and_return(true)
      expect(Open3).to(
        receive(:capture3)
        .with({ 'ENV' => PackageProvider.env }, /.*init_repo.sh/, any_args)
        .once
        .and_return(['', '', status])
      )
    end
  end

  after(:all) do
    FakeFS.deactivate!
  end

  describe '#initialize' do
    it 'constructor creates folder' do
      expect(Dir.exist?(repo.repo_root)).to be true
    end

    it 'raise exception if local folder to clone does\'nt exists', :skip_hook do
      expect do
        PackageProvider::Repository.new(
          'https://github.com/AVGTechnologies/package_provider',
          '/path_not_exist'
        )
      end.to raise_error(PackageProvider::Repository::InvalidRepoPath)
    end
  end

  describe '#clone' do
    let(:treeish) { '4642e6cbebcaa4a7bf94703da1d8ab827b801b34' }
    let(:dest_dir) { '/tt' }
    let(:paths) { ['README.md'] }

    it 'calls 3x Open3::capture' do
      status = double(:status)
      expect(status).to receive(:success?).twice.and_return(true)
      allow(status).to receive(:exitstatus).and_return(0)

      expect(repo).to receive(:fetch!).once

      FileUtils.mkdir_p(File.join(repo.repo_root, '.git', 'info'))

      expect(Open3).to(
        receive(:capture3)
        .with({ 'ENV' => PackageProvider.env }, /.*clone.sh/, any_args)
        .once.and_return(['', '', status])
      )

      repo.clone(dest_dir, treeish, paths, false)
      file_path = File.join(repo.repo_root, '.git', 'info', 'sparse-checkout')
      expect(File.read(file_path)).to eq paths.join("\n") + "\n"
    end

    it 'raise exception when destination folder exists' do
      dir_path = Dir.mktmpdir(PackageProvider::Repository.temp_prefix)

      expect do
        repo.clone(dir_path, nil, [], false)
      end.to raise_error(PackageProvider::Repository::InvalidRepoPath)

      FileUtils.rm_rf(dir_path)
    end
  end

  describe '#destroy' do
    it 'cleans up repo_root' do
      expect(Dir.exist?(repo.repo_root)).to be true
      repo.destroy
      expect(Dir.exist?(repo.repo_root)).to be false
    end
  end

  describe '#metriks_key' do
    context 'returns metricks key for' do
      it 'http://github' do
        expect(repo.send(:metriks_key))
          .to eq('AVGTechnologies_package_provider')
      end

      it 'ssh://github' do
        expect(repo2.send(:metriks_key)).to eq('ondrej_hosak_package_provider')
      end

      it 'https://stash' do
        expect(repo3.send(:metriks_key)).to eq('scm_xxx_package_provider')
      end

      it 'ssh://stash' do
        expect(repo4.send(:metriks_key)).to eq('xxx_package_provider')
      end

      it 'local path' do
        expect(repo5.send(:metriks_key)).to eq('tmp_package_provider')
      end

      it 'local short path' do
        expect(repo6.send(:metriks_key)).to eq('package_provider')
      end
    end
  end

  describe '::commit_hash' do
    let(:status) { double(:status) }
    before(:each) do |example|
      unless example.metadata[:skip_git]
        expect(Open3).to(
          receive(:capture3)
          .with(any_args)
          .once
          .and_return(['04e6f46c05860f1be0c9c8a0605628e188d282ce refs/heads/master', '', status])
        )
      end
    end

    it 'returns commit hash', :skip_hook do
      expect(status).to receive(:success?).and_return(true)

      expect(PackageProvider::Repository.commit_hash(request))
        .to eq('04e6f46c05860f1be0c9c8a0605628e188d282ce')
    end

    it 'throws exception on nil branch', :skip_hook, :skip_git do
      expect do
        PackageProvider::Repository.commit_hash(request_with_nil_branch)
      end.to raise_error(ArgumentError)
    end

    it 'throws exception on non-existing branch', :skip_hook do
      expect(status).to receive(:success?).and_return(false)
      expect(status).to receive(:exitstatus).twice.and_return(2)

      expect do
        PackageProvider::Repository.commit_hash(request_with_wrong_branch)
      end.to raise_error(PackageProvider::Repository::GitError)
    end

    it 'throw exception on non-existing repo', :skip_hook do
      expect(status).to receive(:success?).and_return(false)
      expect(status).to receive(:exitstatus).twice.and_return(128)

      expect do
        PackageProvider::Repository.commit_hash(request_with_wrong_branch)
      end.to raise_error(PackageProvider::Repository::GitError)
    end
  end
end
