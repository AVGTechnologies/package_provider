require 'logger'
require 'raven'
require 'metriks'
require 'metriks/reporter/graphite'
require 'zip'
require 'sidekiq'

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
      setup_zip
      setup_sidekiq
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

    def setup_zip
      Zip.setup do |c|
        c.on_exists_proc = true
        c.continue_on_exists_proc = true
        c.unicode_names = true
        c.default_compression = config.zip.default_compression
      end
    end

    def setup_sidekiq
      Sidekiq.default_worker_options = { 'backtrace' => true } if
        config.log_level == Logger::DEBUG
    end
  end
end
