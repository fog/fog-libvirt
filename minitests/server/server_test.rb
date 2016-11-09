require 'test_helper'

class ServerTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
    @server = @compute.servers.new(:name => "test")
  end

  def test_addresses_calls_compat_version_for_no_dhcp_leases_support
    mocked_client = MiniTest::Mock.new
    network = Libvirt::Network.new
    @compute.stubs(:client).returns(mocked_client)
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).raises(NoMethodError)
    @server.expects(:addresses_ip_command).returns(true)

    @server.send(:addresses)
    mocked_client.verify
  end

  def test_addresses_calls_compat_version_for_older_libvirt
    mocked_client = MiniTest::Mock.new
    network = Libvirt::Network.new
    @compute.stubs(:client).returns(mocked_client)
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).returns(true)
    mocked_client.expect(:libversion, 1002007)
    @server.expects(:addresses_ip_command).returns(true)

    @server.send(:addresses)
    mocked_client.verify
  end

  def test_addresses_calls_compat_version_for_newer_libvirt
    mocked_client = MiniTest::Mock.new
    network = Libvirt::Network.new
    @compute.stubs(:client).returns(mocked_client)
    @compute.expects(:networks).returns([network])
    network.expects(:dhcp_leases).returns(true)
    mocked_client.expect(:libversion, 1002008)
    @server.expects(:addresses_dhcp).returns(true)

    @server.send(:addresses)
    mocked_client.verify
  end
end
