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

      expect(repo).to receive(:fetch).with(treeish).once

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

  describe '#fetch' do
    it 'calls 2x Open3::capture3' do
      status = double(:status)
      expect(status).to receive(:success?).twice.and_return(true)

      expect(Open3).to(
        receive(:capture3)
        .with({}, 'git', any_args)
        .once
        .and_return(['', '', status])
      )

      repo.fetch(nil)
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
end
