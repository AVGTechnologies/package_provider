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
      override = PackageProvider::FolderOverride.new('lib', 'docs')

      expect_any_instance_of(PackageProvider::ZipFileGenerator).to receive(:add_folder).once

      subject.add_folder(package_path, override)
    end
  end
  describe '#write' do
    it 'calls zip archive write' do
      expect_any_instance_of(PackageProvider::ZipFileGenerator).to receive(:write).once

      subject.flush
    end
  end
end
