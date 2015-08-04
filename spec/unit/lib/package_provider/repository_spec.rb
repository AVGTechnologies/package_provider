describe PackageProvider::Repository do
  let(:repo) { PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git') }
  after(:each) do
    repo.destroy
  end

  it 'class initialized' do
    expect(Open3).to receive(:capture3).once
    expect(Dir.exists?(repo.repo_root)).to be true
  end
  it 'raise exception when local folder to clone does not exists' do
    expect {
      PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git','/bla/bla')
    }.to raise_error(PackageProvider::Repository::InvalidRepoPath)
  end
  it 'fetch calls Open3::capture3' do
    expect(Open3).to receive(:capture3).twice
    repo.fetch
  end
end
