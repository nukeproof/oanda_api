# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'oanda_api/version'
require 'time'

Gem::Specification.new do |s|
  s.name        = "oanda_api"
  s.authors     = ["Dean Missikowski"]
  s.email       = "dmissikowski@gmail.com"
  s.homepage    = "http://github.com/nukeproof/oanda_api"
  s.summary     = %q{ A ruby client for the Oanda REST API. }
  s.description = %q{ A simple ruby client that supports all of the Oanda REST API methods. Uses Oanda recommended best practices including persistent connections, compression, request rate throttling, SSL certificate verification.}
  s.version     = OandaAPI::VERSION
  s.date        = Date.today.to_s
  s.license     = "MIT"

  s.required_ruby_version = ">= 2.0.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "httparty",                  "~> 0.13"
  s.add_dependency "persistent_httparty",       "~> 0.1"
  s.add_dependency "http-exceptions",           "~> 0.0"

  s.add_development_dependency "rspec",         "~> 3.1"
  s.add_development_dependency "vcr",           "~> 2.9"
  s.add_development_dependency "webmock",       "~> 1.20"
  s.add_development_dependency "yard",          "~> 0.8"
end
