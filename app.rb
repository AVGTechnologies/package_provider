require './lib/package_provider/repository'

repo = PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git')
puts repo.repo_folder
repo.fetch
repo.destroy
