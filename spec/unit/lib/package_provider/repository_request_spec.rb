describe PackageProvider::RepositoryRequest do
  let(:subject) do
    part = PackageProvider::RepositoryRequest.new(
      'package_provider', nil, 'fake_branch')

    part.add_folder_override('b', 'a')
    part.add_folder_override('.gitmodules', nil)
    part.add_folder_override('a', 'b')

    part
  end

  let(:subject2) do
    part = PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', nil)

    part.add_folder_override('b', 'b')
    part.add_folder_override('a')
    part.add_folder_override('b')
    part.add_folder_override('a', 'a')

    part
  end

  let(:subject3) do
    PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', 'fake_branch')
  end

  let(:subject4) do
    PackageProvider::RepositoryRequest.new('fake_repo', nil, 'fake_branch')
  end

  let(:subject5) do
    PackageProvider::RepositoryRequest.new('fake_repo', 'fake_commit', nil)
  end

  let(:subject6) do
    PackageProvider::RepositoryRequest.new(nil, 'fake_commit', nil)
  end

  let(:subject7) do
    part = PackageProvider::RepositoryRequest.new('repo', 'fake_commit', nil)
    part.add_folder_override(nil)
    part
  end

  let(:subject8) do
    PackageProvider::RepositoryRequest.new(
      'git@github.com:AVGTechnologies/package_provider.git', 'commit', nil)
  end

  let(:subject9) do
    PackageProvider::RepositoryRequest.new(
      'ssh://git@github.com:AVGTechnologies/package_provider.git', 'cmt', nil)
  end

  let(:subject10) do
    PackageProvider::RepositoryRequest.new(
      'ssh://github.com:AVGTechnologies/package_provider.git', 'commit', nil)
  end

  describe '#submodules?' do
    it 'sets git modules true when .gitmodules is present' do
      expect(subject.submodules?).to be true
    end
    it 'not sets git modules false when .gitmodules is missing' do
      expect(subject2.submodules?).to be false
    end
  end

  describe '#to_json' do
    it 'returns json formated class with folder overide' do
      expect(subject.to_json).to eql(
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
      expect(subject3.to_json).to eql(
        MultiJson.dump(
          repository: 'fake_repo',
          branch: 'fake_branch',
          commit: 'fake_commit',
          folderOverride: nil))
    end
  end

  describe '#normalize!' do
    it 'adds default folder override' do
      subject3.normalize!
      expect(subject3.folder_override).to eq(
        [PackageProvider::RepositoryRequest::FolderOverride.new(
          *PackageProvider.config.default_folder_override)]
      )
    end
    it 'rewrites repo alias' do
      subject.normalize!
      expect(subject.repo).to eq(
        PackageProvider::RepositoryAlias.find('package_provider').url
      )
    end

    it 'adds ssh:// prefix' do
      subject8.normalize!
      expect(subject8.repo).to eq(
        'ssh://git@github.com:AVGTechnologies/package_provider.git')
    end

    it 'doesn\'t adds ssh:// prefix for other formats' do
      repo = subject4.repo
      subject4.normalize!
      expect(subject4.repo).to eq(repo)
    end

    it 'doesn\'t adds ssh:// prefix if present' do
      repo = subject9.repo
      subject9.normalize!
      expect(subject9.repo).to eq(repo)
    end

    it 'doesn\'t adds ssh:// prefix if username not present' do
      repo = subject10.repo
      subject10.normalize!
      expect(subject10.repo).to eq(repo)
    end
  end

  describe '#checkout_mask' do
    it 'returns checkout mask' do
      expect(subject.checkout_mask).to eq(['b', '.gitmodules', 'a'])
    end
  end

  describe '#to_tsd' do
    it 'returns well formated simple request' do
      expect(subject3.to_tsd)
        .to eq('fake_repo|fake_branch:fake_commit')
    end
    it 'returns well formated request with branch' do
      expect(subject4.to_tsd)
        .to eq('fake_repo|fake_branch')
    end
    it 'returns well formated request with commit hash' do
      expect(subject5.to_tsd)
        .to eq('fake_repo|fake_commit')
    end
    it 'returns well formated request with folder override' do
      expect(subject2.to_tsd)
        .to eq('fake_repo|fake_commit(b>b,a,b,a>a)')
    end
  end

  describe '#valid?' do
    it 'returns true if everthing is ok' do
      expect(subject2.valid?).to be true
    end
    it 'returns false if repo is not specified' do
      expect(subject6.valid?).to be false
    end
    it 'returns false if commit hash is not specified' do
      expect(subject4.valid?).to be false
    end
  end

  describe '#errors' do
    it 'returns error if repo is missing' do
      expect(subject6.errors).to eq(['Repository is missing'])
    end
    it 'returns error if commit hash is missing' do
      expect(subject4.errors).to eq(['Commit hash is missing'])
    end
  end
end

describe PackageProvider::RepositoryRequest::FolderOverride do
  let(:subject) do
    PackageProvider::RepositoryRequest::FolderOverride.new('source', 'dest')
  end
  let(:subject2) do
    PackageProvider::RepositoryRequest::FolderOverride.new(nil, '/')
  end
  let(:subject3) do
    PackageProvider::RepositoryRequest::FolderOverride.new('source', '/')
  end
  let(:subject4) do
    PackageProvider::RepositoryRequest::FolderOverride.new('source', '\\')
  end

  describe '#new' do
    it 'handles empty source' do
      fo = PackageProvider::RepositoryRequest::FolderOverride.new('', 'test')
      expect(fo.source).to be nil
    end

    it 'handles nil source' do
      fo = PackageProvider::RepositoryRequest::FolderOverride.new(nil, 'test')
      expect(fo.source).to be nil
    end

    it 'handles empty destination' do
      fo = PackageProvider::RepositoryRequest::FolderOverride.new('test', '')
      expect(fo.destination).to be nil
    end

    it 'handles nil destination' do
      fo = PackageProvider::RepositoryRequest::FolderOverride.new('test', nil)
      expect(fo.destination).to be nil
    end
  end

  describe '#valid' do
    it 'returns true if folder override is ok' do
      expect(subject.valid?).to be true
    end
    it 'returns false if has no source and des starts with /' do
      expect(subject2.valid?).to be false
    end
    it 'returns false if destination starts with /' do
      expect(subject3.valid?).to be false
    end
    it 'returns false if destination starts with \\' do
      expect(subject4.valid?).to be false
    end
  end

  describe '#errors' do
    it 'returns empty array if folder override is ok' do
      expect(subject.errors)
        .to eq []
    end

    it 'returns errors if no source and des starts with /' do
      expect(subject2.errors)
        .to eq(['Source is missing', 'Destination can not start with \\ or /'])
    end

    it 'returns error if destination starts with /' do
      expect(subject3.errors)
        .to eq(['Destination can not start with \\ or /'])
    end

    it 'returns error if destination starts with \\' do
      expect(subject4.errors)
        .to eq(['Destination can not start with \\ or /'])
    end

    it 'returns error if source contains //' do
      subject_with_bad_source =
        PackageProvider::RepositoryRequest::FolderOverride.new('foo//bar')
      expect(subject_with_bad_source.errors)
        .to eq ['Source can not contain \\\\ or //']
    end

    it 'returns error if source contains \\\\' do
      subject_with_bad_source =
        PackageProvider::RepositoryRequest::FolderOverride.new('foo\\\\bar')
      expect(subject_with_bad_source.errors)
        .to eq ['Source can not contain \\\\ or //']
    end

    it 'returns error if destination contains //' do
      subject_with_bad_source =
        PackageProvider::RepositoryRequest::FolderOverride.new(
          'foo',
          'bar//baz')
      expect(subject_with_bad_source.errors)
        .to eq ['Destination can not contain \\\\ or //']
    end

    it 'returns error if destination contains \\\\' do
      subject_with_bad_source =
        PackageProvider::RepositoryRequest::FolderOverride.new(
          'foo',
          'bar\\\\baz')
      expect(subject_with_bad_source.errors)
        .to eq ['Destination can not contain \\\\ or //']
    end

    it 'returns all errors' do
      subject_with_two_errors =
        PackageProvider::RepositoryRequest::FolderOverride.new(
          'foo//bar',
          '/baz')
      expect(subject_with_two_errors.errors)
        .to eq ['Source can not contain \\\\ or //',
                'Destination can not start with \\ or /']
    end
  end
end
