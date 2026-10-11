require 'test_helper'

# Attaching a disk to the SCSI bus used to rely on libvirt creating an
# implicit controller. On Q35 that implicit controller is a legacy
# lsilogic device, which RHEL cloud images cannot drive: the cloud-init
# user-data ISO was never seen by the guest, breaking image-based
# provisioning. An explicit virtio-scsi controller must instead be
# declared, exactly once, whenever a disk uses the SCSI bus.
class ScsiControllerTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
  end

  def new_server(attributes = {})
    @compute.servers.new({ :name => "test", :nics => [] }.merge(attributes))
  end

  def scsi_controller_count(xml)
    xml.scan(/<controller[^>]*type="scsi"/).size
  end

  def assert_single_virtio_scsi_controller(xml)
    assert_equal 1, scsi_controller_count(xml)
    assert_match(/<controller[^>]*model="virtio-scsi"/, xml)
  end

  def test_user_data_iso_declares_virtio_scsi_controller
    server = new_server
    server.iso_file = "cloud-init.iso"

    assert_single_virtio_scsi_controller(server.to_xml)
  end

  def test_disks_on_virtio_bus_do_not_get_a_scsi_controller
    server = new_server(:volumes => [{ :path => "/dev/vg_storage01/volume01", :pool_name => "pool" }])

    assert_equal 0, scsi_controller_count(server.to_xml)
  end

  def test_s390x_declares_a_single_virtio_scsi_controller
    server = new_server(:arch => "s390x")

    assert_single_virtio_scsi_controller(server.to_xml)
  end

  def test_s390x_with_user_data_iso_does_not_duplicate_the_controller
    server = new_server(:arch => "s390x")
    server.iso_file = "cloud-init.iso"

    assert_single_virtio_scsi_controller(server.to_xml)
  end

  def test_ceph_disk_on_scsi_bus_declares_virtio_scsi_controller
    server = new_server(:volumes => [ceph_volume])
    server.stubs(:read_ceph_args).returns(ceph_args("scsi"))

    assert_single_virtio_scsi_controller(server.to_xml)
  end

  def test_ceph_disk_on_virtio_bus_does_not_get_a_scsi_controller
    server = new_server(:volumes => [ceph_volume])
    server.stubs(:read_ceph_args).returns(ceph_args("virtio"))

    assert_equal 0, scsi_controller_count(server.to_xml)
  end

  private

  def ceph_volume
    { :path => "fog-pool/volume01", :pool_name => "fog-pool", :format_type => "raw" }
  end

  def ceph_args(bus_type)
    {
      "libvirt_ceph_pool" => "fog-pool",
      "bus_type" => bus_type,
      "monitor" => "10.0.0.1",
      "port" => "6789",
      "auth_username" => "admin",
      "auth_uuid" => "d4f88f7d-9a1e-4c65-a80c-1f5c31a57b2e"
    }
  end
end
