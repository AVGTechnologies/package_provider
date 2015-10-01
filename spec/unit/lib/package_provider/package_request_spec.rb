describe PackageProvider::PackageRequest do
  let(:simple_request) do
    PackageProvider::RepositoryRequest.new(
      'package_provider', 'fake_commit', nil)
  end

  let(:request) do
    part = PackageProvider::RepositoryRequest.new(
      'fake_repo', 'fake_commit', 'fake_branch')

    part.add_folder_override('b', 'b')
    part.add_folder_override('a')
    part.add_folder_override('b')
    part.add_folder_override('a', 'a')

    part
  end

  let(:subject) do
    subject = PackageProvider::PackageRequest.new
    subject << simple_request
    subject
  end

  let(:subject2) do
    subject = PackageProvider::PackageRequest.new
    subject << simple_request
    subject << request
    subject
  end

  describe '#to_tsd' do
    it 'returns one request well formated' do
      expect(subject.to_tsd)
        .to eq('package_provider|fake_commit')
    end
    it 'returns multiple requests well formated' do
      expect(subject2.to_tsd)
        .to eq('package_provider|fake_commit,' \
               'fake_repo|fake_branch:fake_commit(b>b,a,b,a>a)')
    end
  end
end
