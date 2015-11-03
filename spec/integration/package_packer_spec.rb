describe 'PackagePacker integration' do
  test_path = '/tmp/pp_test'
  source_path = PackageProvider.root + '/spec/factories/testing-packer-folder'
  package_path = '/tmp/result_pp'
  ns = PackageProvider::RepositoryRequest

  before(:all) do
    FileUtils.cp_r(source_path, test_path)
  end

  before(:each) do
    Dir.mkdir(package_path)
  end

  after(:all) do
    FileUtils.rm_rf(test_path)
  end

  after(:each) do
    FileUtils.rm_rf(package_path)
  end

  let(:subject) { PackageProvider::PackagePacker.new(package_path) }

  describe '#add_folder' do
    it 'adds overrided folder to final archive' do
      subject.add_folder(test_path, ns::FolderOverride.new('lib', 'docs'))
      subject.flush

      zip = Zip::File.open(package_path + '/package.zip')

      expect(zip.find_entry('docs/app.rb')).not_to be nil
      expect(zip.find_entry('lib/app.rb')).to be nil
    end

    it 'adds folder to final archive' do
      subject.add_folder(test_path, ns::FolderOverride.new('docs', nil))
      subject.flush

      zip = Zip::File.open(package_path + '/package.zip')

      expect(zip.find_entry('test.md')).not_to be nil
    end

    it 'adds overrided file to final archive' do
      subject.add_folder(
        test_path, ns::FolderOverride.new('lib/app.rb', 'docs'))
      subject.flush

      zip = Zip::File.open(package_path + '/package.zip')

      expect(zip.find_entry('docs/app.rb')).not_to be nil
      expect(zip.find_entry('lib/app.rb')).to be nil
    end

    it 'adds file to final archive' do
      subject.add_folder(test_path, ns::FolderOverride.new('lib/app.rb', nil))
      subject.flush

      zip = Zip::File.open(package_path + '/package.zip')

      expect(zip.find_entry('app.rb')).not_to be nil
    end
  end

  describe '#flush' do
    it 'creates zip archive' do
      subject.flush

      expect(File.exist?(package_path + '/package.zip')).to be true
    end
  end
end
