$LOAD_PATH << 'lib'
require 'sidekiq'
require 'package_provider'
require 'package_provider/repository_connection_pool'
require 'package_provider/workers/repository_worker'

PackageProvider.setup
PackageProvider.logger = Sidekiq.logger
PackageProvider.logger.level = PackageProvider.config.log_level

ReposPool = PackageProvider::RepositoryConnectionPool.new
