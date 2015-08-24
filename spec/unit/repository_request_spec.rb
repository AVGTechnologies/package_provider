describe PackageProvider::RepositoryRequest do
  let(:subject) do
    part = PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', nil)

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
    part = PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', 'fake_branch')

    part
  end

  describe '#add_folder_override' do
    it 'sorts out correctly folder override' do
      expect(subject2.folder_override).to eq(
        [PackageProvider::RepositoryRequest::FolderOverride.new('a'),
         PackageProvider::RepositoryRequest::FolderOverride.new('a', 'a'),
         PackageProvider::RepositoryRequest::FolderOverride.new('b'),
         PackageProvider::RepositoryRequest::FolderOverride.new('b', 'b')])
    end
  end

  describe '#submodules?' do
    it 'sets git modules true when .gitmodules is present' do
      expect(subject.use_submodules?).to be true
    end
    it 'not sets git modules false when .gitmodules is missing' do
      expect(subject2.use_submodules?).to be false
    end
  end

  describe '#to_json' do
    it 'returns json formated class with folder overide' do
      expect(subject.to_json).to eql(
        MultiJson.dump(
          repository: 'fake_repo',
          branch: nil,
          commit: 'fake_commit',
          folderOverride: [
            { source: '.gitmodules', destinationOverride: nil },
            { source: 'a', destinationOverride: 'b' },
            { source: 'b', destinationOverride: 'a' }]))
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
end
