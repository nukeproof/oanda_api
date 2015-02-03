lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oanda_api'

RSpec.configure do |c|
  c.before(:suite) do
    # Disable request throttling because all examples are stubbed with VCR and webmock.
    OandaAPI.configure { |config| config.use_request_throttling = false }
  end
end
