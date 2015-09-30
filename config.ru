$LOAD_PATH << 'lib'

require 'bundler/setup'
require 'package_provider/app'

run PackageProvider::App.new
