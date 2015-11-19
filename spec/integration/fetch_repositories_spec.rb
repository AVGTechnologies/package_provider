require 'package_provider/repository_fetcher'

describe 'Repository Fetcher integration' do
  let(:test_dir) { '/var/tmp/test_repo' }
  let(:test_dir2) { '/var/tmp/test_repo2' }
  let(:status) { double(:status) }
  let(:config) do
    {
      'RepositoryAddress' => { 'cache_dir' => test_dir },
      'RepositoryAddress2' => { 'cache_dir' => test_dir },
      'RepositoryAddress3' => { 'cache_dir' => test_dir2 }
    }
  end

  before(:each) do
    allow(PackageProvider::RepositoryConfig).to receive(:repositories)
      .and_return(config)

    allow(status).to receive(:success?)
      .and_return(true)
  end

  it 'it calls fetch on all unique directories' do
    repository_fetcher = PackageProvider::RepositoryFetcher.new(
      PackageProvider::RepositoryConfig.repositories)

    expect(Open3).to receive(:capture3)
      .with({}, 'git fetch --all', chdir: test_dir)
      .and_return([nil, nil, status])

    expect(Open3).to receive(:capture3)
      .with({}, 'git fetch --all', chdir: test_dir2)
      .and_return([nil, nil, status])

    repository_fetcher.fetch_all
  end
end
