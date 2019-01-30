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

  def test_ssh_ip_command_success
    fog_ssh = MiniTest::Mock.new
    result = MiniTest::Mock.new
    result.expect(:status, 0)
    result.expect(:stdout, "any_ip")
    fog_ssh.expect(:run, [result], [String])
    uri = ::Fog::Libvirt::Util::URI.new('qemu+ssh://localhost:22?keyfile=nofile')
    Fog::SSH.stub(:new, fog_ssh) do
      @server.send(:ssh_ip_command, "test command", uri)
    end
    fog_ssh.verify
  end

  def test_local_ip_command_success
    proc_info = MiniTest::Mock.new
    proc_info.expect(:each_line, "127.0.0.1")
    proc_info.expect(:pid, 0)
    status = MiniTest::Mock.new
    status.expect(:exitstatus, 0)
    Process.stubs(:waitpid2).returns([0, status])
    IO.stub(:popen, true, proc_info) do
      @server.send(:local_ip_command, "test command")
    end
    proc_info.verify
    status.verify
  end
end
