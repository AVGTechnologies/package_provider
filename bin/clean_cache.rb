require 'optparse'
require 'yaml'

days = nil
only_failed = nil
OptionParser.new do |opts|
  opts.on('-d',
          '--days DAYS',
          'number of days since file modification (-1 to disable)') { |d| days = d }
  opts.on('--only-failed',
          'clean only files created by failed caching') { |f| only_failed = f }
end.parse!
fail OptionParser::MissingArgument, 'The argument DAYS was not specified.' if
  days.nil?

config_path = File.join(__dir__, '../config/package_provider.yml')
config = YAML.load_file(config_path)['production']

cleaner_script_path = File.join(__dir__, 'delete_old_data.sh')
package_cache_path = File.expand_path(config['package_cache_root'])
repository_cache_path = File.expand_path(config['repository_cache_root'])

params = [cleaner_script_path]
params << '--only-failed' if only_failed
params << days
puts "Cleaning package cache: #{package_cache_path}"
packages_result = system(*params, package_cache_path)
puts "Cleaning repository cache: #{repository_cache_path}"
repos_result = system(*params, repository_cache_path)

exit 1 unless packages_result && repos_result
