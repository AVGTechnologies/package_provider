source 'https://rubygems.org'

ruby '2.2.2'

gem 'activesupport',    '~> 4.2'
gem 'sentry-raven',     '~> 0.14'
gem 'metriks',          '~> 0.9'

gem 'settingslogic',    '~> 2.0'
gem 'multi_json',       '~> 1.0'

gem 'rack'
gem 'rack-contrib'
# see https://github.com/resque/resque/issues/934
gem 'sinatra',          '~> 1.4.6', require: 'sinatra/base'
gem 'sinatra-contrib',  '~> 1.4.4'

gem 'unicorn'

group :test, :development do
  gem 'rspec'
  gem 'rack-test'
  gem 'fakefs'
  gem 'rubocop'
  gem 'codeclimate-test-reporter', require: nil
end
