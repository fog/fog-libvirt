require_relative "../test_helper"
require "nokogiri"
require "json"

class DisksTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
  end

  def ceph_uuid_xml
    <<~XML
      <disk type="network" device="disk">
            <driver name="qemu" type="raw" cache="writeback" discard="unmap"/>
            <source protocol="rbd" name="pool/disk"/>
            <host name="example.org" port="6789"/>
            <host name="192.168.1.4" port="6789"/>
            <auth username="admin">
              <secret type="ceph" uuid="c1384583-fed9-4be8-a233-502ca696c912"/>
            </auth>
            <target dev="vda" bus="scsi"/>
          </disk>
    XML
  end

  def ceph_usage_xml
    <<~XML
      <disk type="network" device="disk">
            <driver name="qemu" type="raw" cache="writeback" discard="unmap"/>
            <source protocol="rbd" name="pool/disk"/>
            <auth username="admin">
              <secret type="ceph" usage="ceph-secret"/>
            </auth>
            <target dev="vda" bus="virtio"/>
          </disk>
    XML
  end

  def ceph_server(options)
    stub_ceph_config(options)
    create_server(:disks => [], :volumes => [{ :path => "pool/disk", :pool_name => "ceph-pool", :format_type => "raw" }])
  end

  def stub_ceph_config(options)
    config = { "libvirt_ceph_pool" => "ceph-pool", "auth_username" => "admin" }.merge(options)
    conf_path = "/etc/foreman/ceph.conf".freeze
    File.expects(:file?).with(conf_path).returns(true).at_least_once
    File.expects(:readlines).with(conf_path).returns(config.map { |key, value| "#{key}=#{value}" }).at_least_once
  end

  def test_ceph
    assert_ceph_disk(ceph_server("auth_uuid" => "c1384583-fed9-4be8-a233-502ca696c912", "monitor" => "example.org,192.168.1.4", "port" => "6789"), ceph_uuid_xml)
    assert_ceph_disk(ceph_server("auth_usage" => "ceph-secret", "bus_type" => "virtio"), ceph_usage_xml)
  end

  private

  def assert_ceph_disk(server, expected_xml)
    server.save
    server.reload
    ceph_disk = disks_xml(server).first
    refute_nil ceph_disk

    assert_equal expected_xml.strip, ceph_disk.to_xml.gsub(/^\s*<address\s+[^>]+>\n/, "")
  ensure
    server.destroy(:destroy_volumes => false) if server&.uuid
  end

  def create_server(overrides = {})
    name = "fog-disks-test-#{Fog::Mock.random_letters(8)}"
    @compute.servers.new({ :name => name, :cpus => 1, :memory_size => 262144, :nics => [], :boot_order => [] }.merge(overrides))
  end

  def disks_xml(server)
    Nokogiri::XML(server.to_xml).xpath("//devices/disk")
  end
end
