describe PackageProvider::FolderOverride do
  let(:valid_subject) { PackageProvider::FolderOverride.new('source', 'dest') }
  let(:subject_with_no_source_and_invalid_destination) do
    PackageProvider::FolderOverride.new(nil, '/')
  end
  let(:subject_with_leading_slash_in_destination) do
    PackageProvider::FolderOverride.new('source', '/')
  end
  let(:subject_with_backslash_in_destination) do
    PackageProvider::FolderOverride.new('source', '\\')
  end

  describe '#new' do
    it 'handles empty source' do
      fo = PackageProvider::FolderOverride.new('', 'test')
      expect(fo.source).to be nil
    end

    it 'handles nil source' do
      fo = PackageProvider::FolderOverride.new(nil, 'test')
      expect(fo.source).to be nil
    end

    it 'handles empty destination' do
      fo = PackageProvider::FolderOverride.new('test', '')
      expect(fo.destination).to be nil
    end

    it 'handles nil destination' do
      fo = PackageProvider::FolderOverride.new('test', nil)
      expect(fo.destination).to be nil
    end
  end

  describe '#valid' do
    it 'returns true if folder override is ok' do
      expect(valid_subject.valid?).to be true
    end
    it 'returns false if has no source and destination starts with /' do
      expect(subject_with_no_source_and_invalid_destination.valid?).to be false
    end
    it 'returns false if destination starts with /' do
      expect(subject_with_leading_slash_in_destination.valid?).to be false
    end
    it 'returns false if destination starts with \\' do
      expect(subject_with_backslash_in_destination.valid?).to be false
    end
  end

  describe '#errors' do
    it 'returns empty array if folder override is ok' do
      expect(valid_subject.errors).to eq []
    end

    it 'returns errors if no source and destination starts with /' do
      expect(subject_with_no_source_and_invalid_destination.errors)
        .to eq(['Source is missing', 'Destination can not start with \\ or /'])
    end

    it 'returns error if destination starts with /' do
      expect(subject_with_leading_slash_in_destination.errors)
        .to eq(['Destination can not start with \\ or /'])
    end

    it 'returns error if destination starts with \\' do
      expect(subject_with_backslash_in_destination.errors)
        .to eq(['Destination can not start with \\ or /'])
    end

    it 'returns error if source contains //' do
      subject_with_bad_source = PackageProvider::FolderOverride.new('foo//bar')
      expect(subject_with_bad_source.errors).to eq ['Source can not contain \\\\ or //']
    end

    it 'returns error if source contains \\\\' do
      subject_with_bad_source = PackageProvider::FolderOverride.new('foo\\\\bar')
      expect(subject_with_bad_source.errors).to eq ['Source can not contain \\\\ or //']
    end

    it 'returns error if destination contains //' do
      subject_with_bad_source = PackageProvider::FolderOverride.new('foo', 'bar//baz')
      expect(subject_with_bad_source.errors).to eq ['Destination can not contain \\\\ or //']
    end

    it 'returns error if destination contains \\\\' do
      subject_with_bad_source = PackageProvider::FolderOverride.new('foo', 'bar\\\\baz')
      expect(subject_with_bad_source.errors).to eq ['Destination can not contain \\\\ or //']
    end

    it 'returns all errors' do
      subject_with_two_errors = PackageProvider::FolderOverride.new('foo//bar', '/baz')
      expect(subject_with_two_errors.errors)
        .to eq ['Source can not contain \\\\ or //', 'Destination can not start with \\ or /']
    end
  end
end
