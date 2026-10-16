unless ['false', 'no', '0'].include?(ENV['COVERAGE'].to_s.downcase)
  require 'simplecov'
  SimpleCov.start
end

require 'minitest/autorun'
require 'mocha/minitest'
require 'fileutils'

$: << File.join(File.dirname(__FILE__), '..', 'lib')

logdir = File.join(File.dirname(__FILE__), '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)

ENV['TMPDIR'] = 'test/tmp'
FileUtils.rm_f Dir.glob 'test/tmp/*.tmp'

require 'fog/libvirt'

Fog.credentials[:libvirt_uri] = ENV.fetch("FOG_LIBVIRT_URI", "test:///default")

def real_libvirt?
  Fog.credentials[:libvirt_uri].start_with?("qemu")
end

enable_mocking = ENV.fetch("FOG_MOCK") { (!real_libvirt?).to_s }
Fog.mock! unless ["false", "no", "0"].include?(enable_mocking)
