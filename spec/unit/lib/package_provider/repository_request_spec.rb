describe PackageProvider::RepositoryRequest do
  let(:subject_with_alias_and_folder_override) do
    part = PackageProvider::RepositoryRequest.new('package_provider', nil, 'fake_branch')

    part.add_folder_override('b', 'a')
    part.add_folder_override('.gitmodules', nil)
    part.add_folder_override('a', 'b')

    part
  end

  let(:subject_with_ssh_and_folder_override) do
    part = PackageProvider::RepositoryRequest.new(
      'git@github.com:AVGTechnologies/package_provider.git', 'fake_commit', nil)

    part.add_folder_override('b', 'b')
    part.add_folder_override('a')
    part.add_folder_override('b')
    part.add_folder_override('a', 'a')

    part
  end

  let(:fully_specified_subject) do
    PackageProvider::RepositoryRequest.new('fake_repo', 'fake_commit', 'fake_branch')
  end

  let(:subject_without_repo) { PackageProvider::RepositoryRequest.new(nil, 'fake_commit', nil) }

  let(:subject_with_ssh_and_commit_hash) do
    PackageProvider::RepositoryRequest.new(
      'ssh://git@github.com:AVGTechnologies/package_provider.git', 'cmt', nil)
  end

  let(:subject_with_ssh_and_branch) do
    PackageProvider::RepositoryRequest.new(
      'ssh://github.com:AVGTechnologies/package_provider.git', nil, 'branch')
  end

  let(:subject_with_repo_only) do
    PackageProvider::RepositoryRequest.new('fake_repo', nil, nil)
  end

  describe '#submodules?' do
    it 'sets git modules true when .gitmodules is present' do
      expect(subject_with_alias_and_folder_override.submodules?).to be true
    end
    it 'not sets git modules false when .gitmodules is missing' do
      expect(subject_with_ssh_and_folder_override.submodules?).to be false
    end
  end

  describe '#to_json' do
    it 'returns json formated class with folder overide' do
      expect(subject_with_alias_and_folder_override.to_json).to eql(
        MultiJson.dump(
          repository: 'package_provider',
          branch: 'fake_branch',
          commit: nil,
          folderOverride: [
            { source: 'b', destinationOverride: 'a' },
            { source: '.gitmodules', destinationOverride: nil },
            { source: 'a', destinationOverride: 'b' }]))
    end
    it 'returns json formated class without folder override' do
      expect(fully_specified_subject.to_json).to eql(
        MultiJson.dump(
          repository: 'fake_repo',
          branch: 'fake_branch',
          commit: 'fake_commit',
          folderOverride: nil))
    end
  end

  describe '#normalize!' do
    it 'adds default folder override' do
      fully_specified_subject.normalize!
      expect(fully_specified_subject.folder_override).to eq(
        [PackageProvider::FolderOverride.new(
          *PackageProvider.config.default_folder_override)]
      )
    end
    it 'rewrites repo alias' do
      subject_with_alias_and_folder_override.normalize!
      expect(subject_with_alias_and_folder_override.repo).to eq(
        PackageProvider::RepositoryAlias.find('package_provider').url
      )
    end

    it 'adds ssh:// prefix' do
      subject_with_ssh_and_folder_override.normalize!
      expect(subject_with_ssh_and_folder_override.repo).to eq(
        'ssh://git@github.com:AVGTechnologies/package_provider.git')
    end

    it 'doesn\'t add ssh:// prefix for other formats' do
      repo = fully_specified_subject.repo
      fully_specified_subject.normalize!
      expect(fully_specified_subject.repo).to eq(repo)
    end

    it 'doesn\'t add ssh:// prefix if present' do
      repo = subject_with_ssh_and_commit_hash.repo
      subject_with_ssh_and_commit_hash.normalize!
      expect(subject_with_ssh_and_commit_hash.repo).to eq(repo)
    end

    it 'doesn\'t add ssh:// prefix if username not present' do
      repo = subject_with_ssh_and_branch.repo
      subject_with_ssh_and_branch.normalize!
      expect(subject_with_ssh_and_branch.repo).to eq(repo)
    end
  end

  describe '#checkout_mask' do
    it 'returns checkout mask' do
      expect(subject_with_alias_and_folder_override.checkout_mask).to eq(['b', '.gitmodules', 'a'])
    end
  end

  describe '#to_tsd' do
    it 'returns well formated simple request' do
      expect(fully_specified_subject.to_tsd)
        .to eq('fake_repo|fake_branch:fake_commit')
    end
    it 'returns well formated request with branch' do
      expect(subject_with_ssh_and_branch.to_tsd)
        .to eq('ssh://github.com:AVGTechnologies/package_provider.git|branch')
    end
    it 'returns well formated request with commit hash' do
      expect(subject_with_ssh_and_commit_hash.to_tsd).to eq(
        'ssh://git@github.com:AVGTechnologies/package_provider.git|cmt')
    end
    it 'returns well formated request with folder override' do
      expect(subject_with_ssh_and_folder_override.to_tsd)
        .to eq('git@github.com:AVGTechnologies/package_provider.git|fake_commit(b>b,a,b,a>a)')
    end
  end

  describe '#valid?' do
    it 'returns true if everything is ok' do
      expect(subject_with_ssh_and_folder_override.valid?).to be true
    end
    it 'returns false if repo is not specified' do
      expect(subject_without_repo.valid?).to be false
    end
    it 'returns false if commit hash and branch is not specified' do
      expect(subject_with_repo_only.valid?).to be false
    end
    it 'returns true if branch is present and commit hash is null' do
      expect(subject_with_ssh_and_commit_hash.valid?).to be true
    end
    it 'returns true if commit hash is present and branch is null' do
      expect(subject_with_ssh_and_branch.valid?).to be true
    end
  end

  describe '#errors' do
    it 'returns error if repo is missing' do
      expect(subject_without_repo.errors).to eq(['Repository is missing'])
    end
    it 'returns error if commit hash and branch is missing' do
      expect(subject_with_repo_only.errors).to eq(['Commit hash and branch is missing'])
    end
  end
end
