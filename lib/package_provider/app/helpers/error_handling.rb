# Class representing erro handling on REST API
module ErrorHandling
  # Error states wrapper
  module HaltHelpers
    def halt_with_400(message)
      halt 400, { message: message }.to_json
    end
  end

  def self.registered(app)
    app.helpers HaltHelpers

    app.error JSON::ParserError do |err|
      halt_with_400("Unable to parse JSON: #{err}")
    end

    app.error MultiJson::DecodeError do |err|
      halt_with_400("Unable to decode JSON: #{err}")
    end
  end
end
