require './lib/package_provider/repository'

repo = PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git', '/home/vagrant/repos/avg')
#repo = PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git', '/bla/bla/')
puts repo.repo_root
#repo.fetch
#repo.destroy

#repo2 = PackageProvider::Repository.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git')
#puts repo2.repo_root
#repo2.fetch
#repo2.destroy
