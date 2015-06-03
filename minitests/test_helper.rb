require 'minitest/autorun'
require 'mocha/mini_test'
require 'fileutils'

$: << File.join(File.dirname(__FILE__), '..', 'lib')

logdir = File.join(File.dirname(__FILE__), '..', 'logs')
FileUtils.mkdir_p(logdir) unless File.exist?(logdir)

ENV['TMPDIR'] = 'test/tmp'
FileUtils.rm_f Dir.glob 'test/tmp/*.tmp'

require 'fog/libvirt'

Fog.mock!
Fog.credentials = {
    :libvirt_uri => 'qemu://libvirt/system',
}.merge(Fog.credentials)
