require 'test_helper'

# Bridge and direct interfaces have a nil network name. #addresses used to
# pass that nil straight into a network lookup, which raised. It should instead
# skip network-less nics and resolve an address from a nic that has one.
class NilNetworkAddressTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
    @server = @compute.servers.new(:name => "test")
  end

  def test_returns_nil_without_raising_when_only_nic_has_no_network
    bridge_nic = stub(:network => nil, :mac => "52:54:00:aa:bb:cc")
    @server.stubs(:nics).returns([bridge_nic])
    # No network is ever looked up, so the connection is never touched.
    @server.service.expects(:networks).never

    result = @server.send(:addresses)

    assert_nil result[:public].first
    assert_nil result[:private].first
  end

  def test_skips_network_less_nic_and_resolves_address_from_next
    bridge_nic = stub(:network => nil, :mac => "52:54:00:aa:bb:cc")
    nat_nic = stub(:network => "default", :mac => "52:54:00:01:02:03")
    @server.stubs(:nics).returns([bridge_nic, nat_nic])

    net = stub(:name => "default")
    net.stubs(:dhcp_leases).with("52:54:00:01:02:03").returns([{ "expirytime" => 1000, "ipaddr" => "192.168.122.10" }])
    networks = stub
    networks.stubs(:all).with(:name => "default").returns([net])
    @server.service.stubs(:networks).returns(networks)

    result = @server.send(:addresses)

    assert_equal "192.168.122.10", result[:public].first
    assert_equal "192.168.122.10", result[:private].first
  end
end
