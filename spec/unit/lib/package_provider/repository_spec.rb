describe PackageProvider::Repository do
  it 'folder initialized' do
    repo = PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git')
    expect(repo.repo_folder).to_not be_empty
    repo.destroy
  end
end
