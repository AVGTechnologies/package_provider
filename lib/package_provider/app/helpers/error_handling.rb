# Class representing erro handling on REST API
module ErrorHandling
  # Error states wrapper
  module HaltHelpers
    def halt_with_400
      halt 400, { message: 'Bad request' }.to_json
    end

    def halt_with_422
      record = env['sinatra.error'].record
      errors = record.errors.to_h
      halt 422, {
        message: record.valid? ? 'Validation fails' : env['sinatra.error'].to_s,
        errors: errors.to_h
      }.to_json
    end
  end

  def self.registered(app)
    app.helpers HaltHelpers

    app.error JSON::ParserError, MultiJson::DecodeError do
      halt_with_400('Cannot parse JSON')
    end
  end
end
