require_relative "../test_helper"
require "nokogiri"
require "json"

class DisksTest < Minitest::Test
  def setup
    @compute = Fog::Compute[:libvirt]
  end

  def disk_attrs
    {
      :type => "file",
      :device => "disk",
      :model => "virtio",
      :snapshot => "external",

      :address => { :type => "pci", :domain => "0x0000", :bus => "0x00", :slot => "0x04", :function => "0x0" },
      :backenddomain => "backenddomain-test",
      :backing_store => { :backing_store => { :type => "file", :format => { :type => "raw" }, :source => { :file => "backing2.qcow2" } },
                          :format => { :type => "qcow2", :metadata_cache => { :max_size => { :value => 262144, :unit => 'bytes' } } },
                          :source => { :file => "backing1.qcow2" },
                          :type => "file" },
      :blockio => { :logical_block_size => 512, :physical_block_size => 4096 },
      :boot => { :order => 1 },
      :driver => driver_attrs,
      :geometry => { :cyls => 16383, :heads => 16, :secs => 63 },
      :iotune => { :read_bytes_sec => 1024, :write_iops_sec => 100, :total_bytes_sec_max => 2000 },
      :readonly => false,
      :serial => "1256A43BC",
      :shareable => false,
      :source => source_attrs,
      :target => { :dev => "vdb", :bus => "virtio" },
      :transient => { :share_backing => true }
    }
  end

  def driver_attrs
    {
      :name => "qemu",
      :type => "qcow2",
      :cache => "directsync",
      :error_policy => "enospace",
      :rerror_policy => "stop",
      :io => "native",
      :ioeventfd => true,
      :event_idx => true,
      :copy_on_read => true,
      :discard => "unmap",
      :detect_zeroes => "unmap",
      :discard_no_unref => true,
      :queues => 4,
      :queue_size => 256,
      :statistics => {
        :intervals => [1, 5],
        :latency_histograms => [{ :type => "read", :bins => [0, 10, 20] }]
      },
      :metadata_cache => { :max_size => { :value => 512, :unit => "bytes" } }
    }
  end

  def source_attrs
    {
      :auth => { :username => "admin", :secret => { :type => "ceph", :usage => "ceph secret" } },
      :data_store => { :type => :network, :format => :raw,
                       :source => { :protocol => "rbd", :name => "pool_name/image_name" } },
      :encryption => { :format => :luks, :engine => :qemu,
                       :secrets => [{ :type => :passphrase, :uuid => "ffffffff-0000-43f5-99d6-c0a00d0de3d9" }] },
      :file => "/var/lib/libvirt/images/root.qcow2",
      :seclabels => [{ :model => :apparmor, :relabel => true, :label => "libvirt-profile" }],
      :startup_policy => "optional"
    }
  end

  def disk_all_attrs
    disk_attrs.merge(:driver => driver_all_attrs,
                     :product => "Product",
                     :rawio => true,
                     :readonly => true,
                     :shareable => true,
                     :source => source_all_attrs,
                     :throttlefilters => ["limit1", "limit2"],
                     :vendor => "VENDOR",
                     :wwn => "0x5000039ff00ddeee")
  end

  def driver_all_attrs
    driver_attrs.merge(:iothread => 1,
                       :iothreads => [{ :id => 1, :queues => [1, 2] }])
  end

  def source_all_attrs
    source_attrs.merge(:address => { :type => "pci", :domain => "0x0000", :bus => "0x01", :slot => "0x00", :function => "0x0" },
                       :config => "/etc/libvirt/rbd.cfg",
                       :cookies => [{ :name => "cookie-name", :value => "cookie-value" }],
                       :encryption => source_attrs[:encryption].merge({ :cipher => { :name => "twofish", :size => 256, :mode => :cbc, :hash => :sha256 },
                                                                        :ivgen => { :name => "plain64", :hash => "sha256" } }),
                       :hosts => [{ :name => "hostname", :port => 7000 }],
                       :identity => { :user => "admin", :group => "admin" },
                       :initiator => "iqn.1995-08.org.example:initiator",
                       :known_hosts => "/etc/pki/libvirt/known_hosts",
                       :name => '/path',
                       :protocol => :http,
                       :query => "foo=bar&baz=flurb",
                       :readahead => 200,
                       :reconnect => { :enabled => true, :timeout => 24, :delay => 5 },
                       :reservations => { :managed => false, :migration => true, :source => { :type => "unix", :path => "/tmp/reservation.sock", :mode => :client } },
                       :slices => [{ :type => "storage", :offset => 12345, :size => 123 }],
                       :snapshot => "snapshot-name",
                       :ssl_verify => true,
                       :timeout => 60,
                       :tls => true,
                       :tls_hostname => "example.com")
  end

  def test_xml
    disk = Fog::Libvirt::Compute::Server::Disk.new(disk_all_attrs)
    expected_attrs = JSON.parse(disk_all_attrs.to_json)

    assert_equal expected_attrs, JSON.parse(disk.to_json)

    disk_xml = to_xml(disk)
    disk_xml_node = Nokogiri::XML(disk_xml).at_xpath('//disk')

    parsed_disk = Fog::Libvirt::Compute::Server::Disk.new(Fog::Libvirt::Compute::Server::Disk.parse_xml(disk_xml_node))
    parsed_xml = to_xml(parsed_disk)

    assert_equal disk_xml, parsed_xml
    assert_equal expected_attrs, JSON.parse(parsed_disk.to_json)
  end

  def mirror_attrs
    {
      :type => "file",
      :job => "copy",
      :ready => true,
      :format => { :type => "qcow2" },
      :source => { :file => "/var/lib/libvirt/images/mirror.qcow2" },
      :backing_store => { :type => "file",
                          :format => { :type => "qcow2" },
                          :source => { :file => "/var/lib/libvirt/images/mirror-backing.qcow2" } }
    }
  end

  def disk_mirror_xml
    <<~XML
      <disk type="file" device="disk">
            <mirror type="file" job="copy" ready="yes">
              <format type="qcow2"/>
              <source file="/var/lib/libvirt/images/mirror.qcow2"/>
              <backingStore type="file">
                <format type="qcow2"/>
                <source file="/var/lib/libvirt/images/mirror-backing.qcow2"/>
              </backingStore>
            </mirror>
          </disk>
    XML
  end

  def test_mirror
    disk = Fog::Libvirt::Compute::Server::Disk.new(Fog::Libvirt::Compute::Server::Disk.parse_xml(Nokogiri::XML(disk_mirror_xml).at_xpath("//disk")))
    assert_equal JSON.parse(mirror_attrs.to_json), JSON.parse(disk.mirror.to_json)
  end

  def block_disk_attrs
    {
      :type => "block",
      :device => "disk",
      :driver => { :name => "qemu", :type => "raw" },
      :source => { :dev => "/dev/loop99" },
      :target => { :dev => "vdc", :bus => "virtio" },
      :address => { :type => "pci", :domain => "0x0000", :bus => "0x06", :slot => "0x00", :function => "0x0" },
      :readonly => false,
      :shareable => false
    }
  end

  def disk_server
    create_server(
      :disks => [disk_attrs],
      :user_data => "#cloud-config",
      :volume_name => "#{name}.img",
      :volume_pool_name => @compute.pools.first&.name,
      :volume_format_type => "raw",
      :volume_capacity => "50M",
      :volume_allocation => "64K"
    )
  end

  def data_store_supported?
    @compute.client.libversion >= 10_010_000
  end

  def statistics_supported?
    @compute.client.libversion >= 11_010_000
  end

  def histograms_supported?
    @compute.client.libversion >= 12_001_000
  end

  def expected_disk_attrs
    attrs = disk_attrs
    if statistics_supported?
      attrs[:driver][:statistics].delete(:latency_histograms) unless histograms_supported?
    else
      attrs[:driver].delete(:statistics)
    end

    attrs[:source].delete(:data_store) unless data_store_supported?
    attrs
  end

  EXPECTED_DISK_XML = <<~XML.freeze
    <disk type="file" device="disk" model="virtio" snapshot="external">
          <backenddomain name="backenddomain-test"/>
          <boot order="1"/>
          <geometry cyls="16383" heads="16" secs="63"/>
          <blockio logical_block_size="512" physical_block_size="4096"/>
          <transient shareBacking="yes"/>
          <target dev="vdb" bus="virtio"/>
          <address type="pci" domain="0x0000" bus="0x00" slot="0x04" function="0x0"/>
          <source file="/var/lib/libvirt/images/root.qcow2" startupPolicy="optional">
            <seclabel model="apparmor" relabel="yes">
              <label>libvirt-profile</label>
            </seclabel>
            <encryption format="luks" engine="qemu">
              <secret type="passphrase" uuid="ffffffff-0000-43f5-99d6-c0a00d0de3d9"/>
            </encryption>
            <dataStore type="network">
              <format type="raw"/>
              <source protocol="rbd" name="pool_name/image_name"/>
            </dataStore>
            <auth username="admin">
              <secret type="ceph" usage="ceph secret"/>
            </auth>
          </source>
          <backingStore type="file">
            <format type="qcow2">
              <metadata_cache>
                <max_size unit="bytes">262144</max_size>
              </metadata_cache>
            </format>
            <source file="backing1.qcow2"/>
            <backingStore type="file">
              <format type="raw"/>
              <source file="backing2.qcow2"/>
            </backingStore>
          </backingStore>
          <driver name="qemu" type="qcow2" cache="directsync" error_policy="enospace" rerror_policy="stop" io="native" ioeventfd="on" event_idx="on" copy_on_read="on" discard="unmap" detect_zeroes="unmap" discard_no_unref="on" queues="4" queue_size="256">
            <statistics>
              <statistic interval="1"/>
              <statistic interval="5"/>
              <latency-histogram type="read">
                <bin start="0"/>
                <bin start="10"/>
                <bin start="20"/>
              </latency-histogram>
            </statistics>
            <metadata_cache>
              <max_size unit="bytes">512</max_size>
            </metadata_cache>
          </driver>
          <iotune>
            <read_bytes_sec>1024</read_bytes_sec>
            <write_iops_sec>100</write_iops_sec>
            <total_bytes_sec_max>2000</total_bytes_sec_max>
          </iotune>
          <serial>1256A43BC</serial>
        </disk>
  XML

  def expected_disk_xml
    xml = EXPECTED_DISK_XML
    xml = remove_xml_element(xml, "dataStore") unless data_store_supported?
    xml = remove_xml_element(xml, "statistics") unless statistics_supported?
    xml = remove_xml_element(xml, "latency-histogram") unless histograms_supported?
    xml
  end

  def expected_iso_xml(pool_path, server_name)
    <<~XML
      <disk type="file" device="cdrom">
            <readonly/>
            <target dev="sda" bus="scsi"/>
            <address type="drive" controller="0" bus="0" target="0" unit="0"/>
            <source file="#{pool_path}/#{server_name}-cloud-init.iso"/>
            <driver name="qemu" type="raw"/>
          </disk>
    XML
  end

  def test_disks
    server = disk_server
    server.stubs(:system).returns(true)
    server.disks << block_disk_attrs

    prepare_storage

    server.save
    server.reload

    disks_xml = disks_xml(server)
    assert_equal 1, server.volumes.size
    assert_equal 4, server.disks.size
    assert_equal 4, disks_xml.size

    assert_primary_disk(server)

    assert_equal expected_iso_xml(server.iso_dir, server.name).strip, disks_xml[3].to_xml

    assert_disks(server, disks_xml[1])
    assert_uniq_names(disks_xml)
  ensure
    if server&.iso_file
      @compute.list_volumes(:name => server.iso_file).each do |volume|
        @compute.volume_action(volume[:key], :delete) if volume
      end
    end
    server.destroy(:destroy_volumes => true) if server&.uuid
  end

  def prepare_storage
    return if real_libvirt?

    # test driver doesn't support this
    Libvirt::StorageVol.any_instance.expects(:upload).once
    Libvirt::Stream.any_instance.expects(:sendall).once
    Libvirt::Stream.any_instance.expects(:finish).once
  end

  def assert_primary_disk(server)
    primary_disk = server.disks.first
    assert_equal "vda", primary_disk.target.dev
    assert_equal "file", primary_disk.type
    assert_equal "disk", primary_disk.device
    refute primary_disk.readonly
    assert_equal server.volumes.first.path, primary_disk.source.file
  end

  def assert_disks(server, disk_xml)
    disk = server.disks[1]
    assert_equal JSON.parse(expected_disk_attrs.to_json), JSON.parse(disk.to_json)
    assert_equal expected_disk_xml.strip, disk_xml.to_xml

    block = server.disks[2]
    assert_equal JSON.parse(block_disk_attrs.to_json), JSON.parse(block.to_json)
  end

  def assert_uniq_names(disks_xml)
    devs = disks_xml.map { |disk| disk.at_xpath("target")["dev"] }
    assert_equal devs.uniq, devs
  end

  def ceph_uuid_xml
    <<~XML
      <disk type="network" device="disk">
            <target dev="vda" bus="scsi"/>
            <source protocol="rbd" name="pool/disk">
              <host name="example.org" port="6789"/>
              <host name="192.168.1.4" port="6789"/>
              <auth username="admin">
                <secret type="ceph" uuid="c1384583-fed9-4be8-a233-502ca696c912"/>
              </auth>
            </source>
            <driver name="qemu" type="raw" cache="writeback" discard="unmap"/>
          </disk>
    XML
  end

  def ceph_usage_xml
    <<~XML
      <disk type="network" device="disk">
            <target dev="vda" bus="virtio"/>
            <source protocol="rbd" name="pool/disk">
              <auth username="admin">
                <secret type="ceph" usage="ceph-secret"/>
              </auth>
            </source>
            <driver name="qemu" type="raw" cache="writeback" discard="unmap"/>
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

  def remove_xml_element(xml, name)
    xml.gsub(%r{^\s*<#{name}[^>]*>.*?</#{name}>\n}m, "")
  end

  def to_xml(model)
    Nokogiri::XML::Builder.new { |xml| model.build_xml(xml) }.to_xml
  end

  def disks_xml(server)
    Nokogiri::XML(server.to_xml).xpath("//devices/disk")
  end
end
