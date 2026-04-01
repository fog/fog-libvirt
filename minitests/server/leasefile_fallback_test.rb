require 'test_helper'
require 'tmpdir'

class LeasefileFallbackTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
    @server = @compute.servers.new(:name => "test")
    @mac = "52:54:00:01:02:03"
    @net = stub(:name => "default")
    @tmpdir = Dir.mktmpdir("fog-leasefile-test")
    @original_dir = Fog::Libvirt::Compute::Server::DNSMASQ_LEASE_DIR
    Fog::Libvirt::Compute::Server.send(:remove_const, :DNSMASQ_LEASE_DIR)
    Fog::Libvirt::Compute::Server.const_set(:DNSMASQ_LEASE_DIR, @tmpdir)
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
    Fog::Libvirt::Compute::Server.send(:remove_const, :DNSMASQ_LEASE_DIR)
    Fog::Libvirt::Compute::Server.const_set(:DNSMASQ_LEASE_DIR, @original_dir)
  end

  def test_returns_ip_for_matching_mac
    write_lease_file("default", "1000 52:54:00:01:02:03 192.168.122.10 host1 *\n")
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_equal "192.168.122.10", result
  end

  def test_returns_ip_with_highest_expiry
    content = <<~LEASES
      1000 52:54:00:01:02:03 192.168.122.10 host1 *
      2000 52:54:00:01:02:03 192.168.122.20 host1 *
      1500 52:54:00:01:02:03 192.168.122.15 host1 *
    LEASES
    write_lease_file("default", content)
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_equal "192.168.122.20", result
  end

  def test_mac_matching_is_case_insensitive
    write_lease_file("default", "1000 52:54:00:01:02:03 192.168.122.10 host1 *\n")
    result = @server.send(:ip_address_from_leasefile, @net, "52:54:00:01:02:03".upcase)
    assert_equal "192.168.122.10", result
  end

  def test_returns_nil_when_lease_file_missing
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_nil result
  end

  def test_skips_malformed_lines
    content = <<~LEASES
      short line
      1000 52:54:00:01:02:03 192.168.122.10 host1 *
      incomplete
    LEASES
    write_lease_file("default", content)
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_equal "192.168.122.10", result
  end

  def test_returns_nil_when_no_mac_matches
    write_lease_file("default", "1000 52:54:00:ff:ff:ff 192.168.122.99 other *\n")
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_nil result
  end

  def test_returns_nil_on_permission_error
    skip("Cannot test permission denial as root") if Process.uid == 0
    write_lease_file("default", "1000 52:54:00:01:02:03 192.168.122.10 host1 *\n")
    File.chmod(0o000, File.join(@tmpdir, "default.leases"))
    result = @server.send(:ip_address_from_leasefile, @net, @mac)
    assert_nil result
  end

  def test_returns_nil_when_net_name_is_nil
    net_nil_name = stub(:name => nil)
    result = @server.send(:ip_address_from_leasefile, net_nil_name, @mac)
    assert_nil result
  end

  private

  def write_lease_file(net_name, content)
    File.write(File.join(@tmpdir, "#{net_name}.leases"), content)
  end
end
