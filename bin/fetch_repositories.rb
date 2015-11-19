$LOAD_PATH << 'lib'
require 'package_provider'
require 'package_provider/repository_fetcher'

PackageProvider.setup

PackageProvider.logger.info("Fetch repositories started on #{Time.now}")

repository_fetcher = PackageProvider::RepositoryFetcher.new(
  PackageProvider::RepositoryConfig.repositories)
repository_fetcher.fetch_all
