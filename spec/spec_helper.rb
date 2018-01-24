lib = File.expand_path("../../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'simplecov'
SimpleCov.start

require 'oanda_api'

RSpec.configure do |c|
  c.before(:suite) do
    # Disable request throttling because all examples are stubbed with VCR and webmock.
   WebMock.enable!
   OandaAPI.configure { |config| config.use_request_throttling = false }
  end
end

def jruby?
  defined?(RUBY_ENGINE) && (RUBY_ENGINE =~ /jruby/i)
end

def gem_installed?(const)
  begin
    require const.to_s.downcase unless Object.const_defined? const
    true
  rescue ::LoadError => e
    false
  end
end

# Makes the adapter requirements break (i.e. simulates that a gem required
#  for an adapter is not installed).
def break_requirements
  requirements = OandaAPI::Streaming::JsonParser::REQUIREMENT_MAP
  OandaAPI::Streaming::JsonParser::REQUIREMENT_MAP.each do | adapter, library|
    OandaAPI::Streaming::JsonParser::REQUIREMENT_MAP[adapter] = "foo/#{library}"
  end

  yield
ensure
  requirements.keys do |adapter|
    OandaAPI::Streaming::JsonParser::REQUIREMENT_MAP[adapter] = requirements[adapter]
  end
end

# Silences warnings issued by Kerel.warn
def silence_warnings
  old_verbose, $VERBOSE = $VERBOSE, nil
  yield
ensure
  $VERBOSE = old_verbose
end

def simulate_no_adapters
  break_requirements do
    undefine_constants :Yajl, :Gson do
      yield
    end
  end
end

# Allows examples to change configuration settings, and have the settings returned to their pre-example state.
def reset_configuration(*keys)
  configs = {}
  keys.each { |key| configs[key] = OandaAPI.configuration.send(key) }
  yield
ensure
  configs.each { |key, value| OandaAPI.configuration.send("#{key}=", value) }
end

def undefine_constants(*consts)
  values = {}
  consts.each do |const|
    if Object.const_defined?(const)
      values[const] = Object.const_get(const)
      Object.send :remove_const, const
    end
  end

  yield

  ensure
    values.each do |const, value|
      Object.const_set const, value
    end
end
