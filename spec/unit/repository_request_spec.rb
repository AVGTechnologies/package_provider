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
          repository: 'fake_repo',
          branch: nil,
          commit: 'fake_commit',
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
end
