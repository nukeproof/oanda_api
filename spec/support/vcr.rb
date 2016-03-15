require 'vcr'
VCR.configure do |c|
  c.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.default_cassette_options = { record: :new_episodes }
  c.filter_sensitive_data('<OANDA_TESTING_API_TOKEN>') { ClientHelper.test_account_token }
  c.ignore_hosts 'codeclimate.com'
end
