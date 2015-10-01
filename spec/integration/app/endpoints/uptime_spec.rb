require 'rack/test'

describe 'Application API uptime' do
  include Rack::Test::Methods

  def app
    PackageProvider::App.new
  end

  describe 'uptime API' do
    let(:headers_json) do
      {
        'HTTP_ACCEPT' => 'application/json',
        'CONTENT_TYPE' => 'application/json'
      }
    end
    let(:prefix) { PackageProvider.config.base_url }

    it 'responds to uptime' do
      response = get "#{prefix}/uptime", {}, headers_json
      expect(response.body).to eq(
        "Ready and waiting from #{PackageProvider.start_time}!")
    end
  end
end
