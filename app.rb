require './lib/pp_repo'

repo = PpRepo.new('https://ondrej.hosak@stash.cz.avg.com/scm/ddtf/onlinekitchen.git')
puts repo.repo_folder
repo.fetch
repo.destroy
