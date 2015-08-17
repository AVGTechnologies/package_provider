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

  describe '#add_folder_override' do
    it 'sorts out correctly folder override' do
      ns = PackageProvider::RepositoryRequest

      expect(subject2.folder_override).to eq(
        [ns::PackageRequestFolderOverride.new('a'),
         ns::PackageRequestFolderOverride.new('a', 'a'),
         ns::PackageRequestFolderOverride.new('b'),
         ns::PackageRequestFolderOverride.new('b', 'b')])
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
end
