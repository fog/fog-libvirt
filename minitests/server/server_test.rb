require 'test_helper'

class ServerTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
    @server = @compute.servers.new(:name => "test")
  end

  def test_addresses_calls_compat_version_for_no_dhcp_leases_support
    network = Libvirt::Network.new
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).raises(NoMethodError)
    @server.expects(:addresses_ip_command).returns(true)

    @server.send(:addresses)
  end

  def test_addresses_calls_compat_version_for_older_libvirt
    network = Libvirt::Network.new
    @compute.expects(:libversion).returns(1002007)
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).returns(true)
    @server.expects(:addresses_ip_command).returns(true)

    @server.send(:addresses)
  end

  def test_addresses_calls_compat_version_for_newer_libvirt
    network = Libvirt::Network.new
    @compute.expects(:libversion).returns(1002008)
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).returns(true)
    @server.expects(:addresses_dhcp).returns(true)

    @server.send(:addresses)
  end
end
