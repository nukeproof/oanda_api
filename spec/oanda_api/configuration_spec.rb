require 'spec_helper'

describe "OandaAPI::Configuration" do
  let(:config) { OandaAPI::Configuration.new }

  describe "#connection_pool_size" do
    it "returns the default maximum connection pool size" do
      expect(config.connection_pool_size).to eq OandaAPI::Configuration::CONNECTION_POOL_SIZE
    end
  end

  describe "#connection_pool_size=" do
    it "overrides the default maximum connection pool size" do
      config.connection_pool_size = 10
      expect(config.connection_pool_size).to eq 10
    end

    it "must be numeric" do
      expect { config.connection_pool_size = "X" }.to raise_error(ArgumentError)
    end

    it "must be > 0" do
      [-10, 0].each do |val|
        expect { config.connection_pool_size = val }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#datetime_format" do
    it "returns the default datetime format" do
      expect(config.datetime_format).to eq OandaAPI::Configuration::DATETIME_FORMAT
    end
  end

  describe "#datetime_format=" do
    it "overrides the default datetime format" do
      config.datetime_format = :unix
      expect(config.datetime_format).to eq :unix

      config.datetime_format = :rfc3339
      expect(config.datetime_format).to eq :rfc3339
    end

    it "must be a valid datetime format" do
      expect { config.datetime_format = "X" }.to raise_error(ArgumentError)
    end
  end

  describe "#rest_api_version" do
    it "returns the default rest api version" do
      expect(config.rest_api_version).to eq OandaAPI::Configuration::REST_API_VERSION
    end
  end

  describe "#rest_api_version=" do
    it "overrides the default rest api version" do
      config.rest_api_version = "X"
      expect(config.rest_api_version).to eq "X"
    end
  end

  describe "#max_requests_per_second" do
    it "returns the default max requests per second" do
      expect(config.max_requests_per_second).to eq OandaAPI::Configuration::MAX_REQUESTS_PER_SECOND
    end
  end

  describe "#max_requests_per_second=" do
    it "overrides the default max requests per second" do
      config.max_requests_per_second = 50
      expect(config.max_requests_per_second).to eq 50
    end

    it "must be numeric" do
      expect { config.max_requests_per_second = "X" }.to raise_error(ArgumentError)
    end

    it "must be > 0" do
      [-10, 0].each do |val|
        expect { config.max_requests_per_second = val }.to raise_error(ArgumentError)
      end
    end
  end

  describe "#min_request_interval" do
    it "is the inverse of #max_requests_per_second" do
      config.max_requests_per_second = 2
      expect(config.min_request_interval).to eq(0.5)
    end
  end

  describe "#open_timeout" do
    it "returns the default open timeout" do
      expect(config.open_timeout).to eq OandaAPI::Configuration::OPEN_TIMEOUT
    end
  end

  describe "#open_timeout=" do
    it "overrides the default open timeout" do
      config.open_timeout = 20
      expect(config.open_timeout).to eq 20
    end

    it "must be numeric" do
      expect { config.open_timeout = "X" }.to raise_error(ArgumentError)
    end
  end

  describe "#read_timeout" do
    it "returns the default read timeout" do
      expect(config.read_timeout).to eq OandaAPI::Configuration::READ_TIMEOUT
    end
  end

  describe "#read_timeout=" do
    it "overrides the default read timeout" do
      config.read_timeout = 20
      expect(config.read_timeout).to eq 20
    end

    it "must be numeric" do
      expect { config.read_timeout = "X" }.to raise_error(ArgumentError)
    end
  end

  describe "#use_compression=" do
    it "enables compression" do
      config.use_compression = true
      expect(config.use_compression?).to be true
      expect(config.headers).to include("Accept-Encoding" => "deflate, gzip")
    end

    it "disables compression" do
      config.use_compression = false
      expect(config.use_compression?).to be false
      expect(config.headers).to_not include("Accept-Encoding" => "deflate, gzip")
    end
  end

  describe "#use_request_throttling=" do
    it "enables throttling" do
      config.use_request_throttling = true
      expect(config.use_request_throttling?).to be true
    end

    it "disables throttling" do
      config.use_request_throttling = false
      expect(config.use_request_throttling?).to be false
    end
  end

  describe "#headers" do
    it "is a hash" do
      expect(config.headers).to be_a Hash
    end

    it "includes a date format header" do
      expect(config.headers).to include("X-Accept-Datetime-Format")
    end
  end
end
