describe PackageProvider::PackagePacker do
  package_path = '/tmp/result_pp'

  before(:each) do
    Dir.mkdir(package_path)
  end

  after(:each) do
    FileUtils.rm_rf(package_path)
  end

  let(:subject) { PackageProvider::PackagePacker.new(package_path) }

  describe '#add_folder' do
    it 'calls zip archive add_folder' do
      override = PackageProvider::RepositoryRequest::FolderOverride.new(
        'lib', 'docs')

      expect(subject.zip_generator).to receive(:add_folder).with(any_args)

      subject.add_folder(package_path, override)
    end
  end
  describe '#write' do
    it 'calls zip archive write' do
      expect(subject.zip_generator).to receive(:write)
        .with(any_args)
        .and_return('OK')

      subject.flush
    end
  end
end
