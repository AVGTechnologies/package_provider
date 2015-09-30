ENV['ENV'] = ENV['RACK_ENV'] = ENV['RAILS_ENV'] = ENV['APP_ENV'] = 'test'

$LOAD_PATH << 'lib'

require 'rack'
require 'rspec'

require 'package_provider'
require 'package_provider/repository_request'
require 'package_provider/repository'
require 'package_provider/repository_alias'
require 'package_provider/repository_connection_pool'
require 'package_provider/request_parser/parser'
require 'package_provider/workers/packer_worker'
require 'package_provider/workers/repository_worker'
require 'package_provider/app'
require 'support/helpers'

PackageProvider.setup

RSpec.configure do |config|
  config.include Helpers

  config.filter_run focus: true
  config.filter_run_excluding broken: true
  config.run_all_when_everything_filtered = true
  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end
end
