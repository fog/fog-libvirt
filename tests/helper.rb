ENV['FOG_RC']         = ENV['FOG_RC'] || File.expand_path('../.fog', __FILE__)
ENV['FOG_CREDENTIAL'] = ENV['FOG_CREDENTIAL'] || 'default'

unless ['false', 'no', '0'].include?(ENV['COVERAGE'].to_s.downcase)
  require 'simplecov'
  SimpleCov.start
  SimpleCov.command_name 'Shindo'
end

require 'fog/libvirt'

Excon.defaults.merge!(:debug_request => true, :debug_response => true)

require File.expand_path(File.join(File.dirname(__FILE__), 'helpers', 'mock_helper'))

# This overrides the default 600 seconds timeout during live test runs
if Fog.mocking?
  FOG_TESTING_TIMEOUT = ENV['FOG_TEST_TIMEOUT'] || 2000
  Fog.timeout = 2000
  Fog::Logger.warning "Setting default fog timeout to #{Fog.timeout} seconds"
else
  FOG_TESTING_TIMEOUT = Fog.timeout
end

Thread.current[:tags] ||= []
Thread.current[:tags] << "-requires-mocks" unless Fog.mock?
