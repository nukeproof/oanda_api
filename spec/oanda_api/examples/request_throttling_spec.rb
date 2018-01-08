require 'spec_helper'
require 'support/client_helper'

describe "OandaAPI::Client" do
  let(:client) { ClientHelper.client }

  around do |example|
    reset_configuration(:use_request_throttling,
                        :max_requests_per_second,
                        :max_new_connections_per_second) { example.call }
  end

  context "when NOT using request throttling" do
    it "does NOT limit the request rate of multiple sequential requests", :vcr do
      OandaAPI.configuration.use_request_throttling = false
      VCR.use_cassette("without_throttling") do
        start_time = Time.now
        1.upto(10) { client.prices(instruments: ["EUR_USD"]).get }

        # When running the test from the VCR cassette,
        # the time for each request should be constant and minimal allowing a high
        # request rate.
        #
        # This test may fail if the VCR cassette is not used because of network
        # latency.
        expect(Time.now - start_time).to be > 0.0 && be < 1.0
      end
    end

    #
    # 08 Jan, 2018 - it seems connection rate limiting is not enforced consistently by Oanda
    #                so, removing this test for now.
    #
    # it "does NOT limit the rate of NEW connections", :vcr do
    #   OandaAPI.configuration.use_request_throttling = false
    #   VCR.use_cassette("without_throttling_new_connections") do
    #     message = ""
    #     begin
    #       1.upto(10) do
    #         client = ClientHelper.client force_new: true
    #         client.prices(instruments: "EUR_USD").get
    #       end
    #     rescue OandaAPI::RequestError => e
    #       message = e.message
    #     end
    #     expect(message).to match(/Rate limit violation of newly established connections/)
    #   end
    # end
  end

  context "when using request throttling" do
    it "limits the rate of NEW connections", :vcr do
      OandaAPI.configuration.use_request_throttling = true
      VCR.use_cassette("with_throttling_new_connections") do
        successful_connections = 0
        1.upto(10) do
          client = ClientHelper.client force_new: true
          client.accounts.get
          successful_connections += 1
        end
        expect(successful_connections).to eq 10
      end
    end

    context "with a positive value set for max_requests_per_second" do
      it "limits multiple sequential requests to the rate specified in the requests_per_second setting " do
        OandaAPI.configuration.use_request_throttling = true
        OandaAPI.configuration.max_requests_per_second = 2

        VCR.use_cassette("with_throttling_and_max_requests_per_second") do
          start_time = Time.now
          1.upto(3) { client.prices(instruments: ["EUR_USD"]).get }

          # 3 requests at 2 req/second should take at least 1 second (see below).
          #
          # A limit of 2 requests per second is enforced by waiting 0.5 seconds bewteen requests.
          #
          #    time:   0.0.................0.5.................1.0 (seconds)
          # request:   1st   [wait 0.5s]   2nd   [wait 0.5s]   3rd
          expect(Time.now - start_time).to be > 1.0
        end
      end

      context "when multiple threads make synchronized requests to the same client instance" do
        it "throttles the combined requests made by all threads" do
          OandaAPI.configuration.use_request_throttling = true
          OandaAPI.configuration.max_requests_per_second = 3

          VCR.use_cassette("with_throttling_with_multiple_threads") do

            mutex = Mutex.new
            threads = []
            start_time = Time.now

            # Start up multiple threads
            1.upto(3) do
              threads << Thread.new do
                # Each thread executes multiple API requests
                1.upto(2) do
                  # A thread has exclusive use of the API client while executing a request.
                  mutex.synchronize { client.prices(instruments: ["EUR_USD"]).get }
                end
              end
            end
            threads.each(&:join)

            # 6 requests in total, at 3 req/second should require at least 1.66 seconds (see below).
            #
            # A limit of 3 requests per second is enforced by waiting 1/3 second bewteen requests.
            #
            #    time: 0.0  0.3  0.6  1.0  1.3  1.6  2.0  2.3  2.6 (seconds)
            # request: 1st  2nd  3rd  4th  5th  6th
            expect(Time.now - start_time).to be > 1.6
          end
        end
      end
    end
  end
end
