require 'logger'
require 'raven'
require 'metriks'
require 'metriks/reporter/graphite'

require 'package_provider/config'

# Namespace that handles git operations for PackageProvider
module PackageProvider
  class << self
    # rubocop:disable TrivialAccessors
    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def logger=(l)
      @logger = l
    end
    # rubocop:enable TrivialAccessors
    def config
      @config ||= PackageProvider::Config.new
    end

    def root
      File.expand_path('../..', __FILE__)
    end

    def env
      system_env || 'development'
    end

    attr_reader :start_time

    def setup
      @start_time = Time.now
      logger.level = config.log_level || Logger::WARN
      setup_raven
      setup_metriks
    end

    private

    def system_env
      ENV['ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['APP_ENV']
    end

    def setup_raven
      return unless config.sentry_dsn
      ::Raven.configure do |config|
        config.dsn = PackageProvider.config.sentry_dsn
        config.current_environment = PackageProvider.env
        config.excluded_exceptions = %w(Sinatra::NotFound)
      end
    end

    def setup_metriks
      return unless config.graphite
      reporter = Metriks::Reporter::Graphite.new(
        config.graphite.host,
        config.graphite.port,
        config.graphite.options || {}
      )
      reporter.start
    end
  end
end
