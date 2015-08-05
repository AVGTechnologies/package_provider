require 'logger'

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
    end

    def root
      File.expand_path('../..', __FILE__)
    end

    def env
      system_env || 'development'
    end

    private

    def system_env
      ENV['ENV'] || ENV['RACK_ENV'] || ENV['RAILS_ENV'] || ENV['APP_ENV']
    end
  end
end
