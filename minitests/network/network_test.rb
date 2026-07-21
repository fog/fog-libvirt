require_relative "../test_helper"
require "nokogiri"
require "json"
require "ipaddr"

class NetworkTest < Minitest::Test
  def setup
    @created_networks = []
    @compute = Fog::Compute[:libvirt]
  end

  def teardown
    @created_networks.each do |name|
      @compute.networks.all(:name => name).each(&:destroy)
    end
  end

  def test_model
    network = @compute.networks.new(:name => "default", :uuid => "dd8fe884-6c02-601e-7551-cca97df1c5df", :bridge_name => "virbr0")

    assert_kind_of Fog::Libvirt::Compute::Network, network

    assert network.respond_to? "reload"
    assert network.respond_to? "dhcp_leases"

    attributes = [:name, :uuid, :bridge_name]
    attributes.each do |attribute|
      assert network.respond_to? attribute
      assert network.attributes.key? attribute unless attribute == :bridge_name
    end

    expected = <<~NETWORK
      <?xml version="1.0"?>
      <network>
        <name>default</name>
        <uuid>dd8fe884-6c02-601e-7551-cca97df1c5df</uuid>
        <bridge name="virbr0"/>
      </network>
    NETWORK
    assert_equal expected, network.to_xml
  end

  def test_dhcp_leases
    network = create_network("test-network-model", :uuid => "dd8fe884-6c02-601e-7551-cca97df1c5df")

    if Fog.mock?
      # From models/compute/network/dhcp_lease.rb
      dhcp_leases_mock_data = [{ "type" => 2, "ipaddr" => "1.2.3.4", "prefix" => 24, "expirytime" => 5000 },
                               { "type" => 2, "ipaddr" => "1.2.5.6", "prefix" => 24, "expirytime" => 5005 }]

      assert_equal dhcp_leases_mock_data, network.dhcp_leases("aa:bb:cc:dd:ee:ff", 0)
    elsif real_libvirt?
      assert_kind_of Array, network.dhcp_leases("aa:bb:cc:dd:ee:ff", 0)
    else
      skip("libvirt test driver doesn't support dhcp_leases so can't test without mocking or real libvirt")
    end
  end

  def network_all_attrs
    {
      :uuid => "106c3ca9-04ca-4120-a9a5-c153e41289d9",
      :ipv6 => true,
      :trust_guest_rx_filters => true,
      :name => "fog-test-xml",
      :metadata => %(<metadata>\n  <app1:foo xmlns:app1="http://example.org/app1/"><app1:custom attr="val"/></app1:foo>\n  <app2:bar xmlns:app2="http://app2.example.org/"><something>123</something></app2:bar>\n</metadata>),
      :title => "Title",
      :description => "Description",
      :bridge => { :name => "virbr100", :zone => "dmz", :stp => true, :delay => 5, :mac_table_manager => "libvirt" },
      :mtu => 3000,
      :domain => { :name => "example.local", :local_only => true, :register => false },
      :forward => network_all_forward,
      :bandwidth => network_all_bandwidth,
      :virtualport => network_all_virtualport,
      :vlan => { :trunk => true, :tags => [{ :id => 100, :native_mode => "tagged" }, { :id => 200 }] },
      :portgroups => network_all_portgroups,
      :isolated => true,
      :mac => "f8:ee:dd:cc:bb:aa",
      :dns => network_all_dns,
      :ips => network_all_ips,
      :routes => [{ :gateway => "10.0.0.1", :address => "10.0.0.100", :netmask => "255.255.128.0", :prefix => 17, :family => "ipv4", :metric => 100 }],
      :dnsmasq => { :options => ["foo=bar", "cname=*.foo.example.com,master.example.com"] }
    }
  end

  def network_all_forward
    {
      :mode => :nat, :managed => true,
      :nat => {
        :ipv6 => true,
        :address => { :start => "172.16.24.100", :end => "172.16.27.200" },
        :port => { :start => 1000, :end => 5000 }
      },
      :interfaces => [{ :dev => "eth1" }],
      :pf => "eth0",
      :driver => "vfio",
      :addresses => [{ :type => "pci", :domain => "0x0000", :bus => "0x04",
                       :slot => "0x02", :function => "0x1" }]
    }
  end

  def network_all_bandwidth
    {
      :inbound => { :average => 1000, :peak => 2000, :burst => 256, :floor => 300 },
      :outbound => { :average => 500, :peak => 1000, :burst => 128 }
    }
  end

  def network_all_virtualport
    { :type => "802.1Qbg",
      :interfaceid => "aaaaaaaa-094c-4267-9de0-0f0b40a61389",
      :profileid => "profile",
      :managerid => 11,
      :typeid => 345,
      :typeidversion => 2,
      :instanceid => "bbbbbbbb-a905-474d-bbc0-1ef1920dcd8d" }
  end

  def network_all_portgroups
    [
      { :name => "portgroup",
        :default => true,
        :trust_guest_rx_filters => true,
        :bandwidth => {},
        :virtualport => { :type => "openvswitch", :interfaceid => "cccccccc-ac59-4b03-9a61-bc28e5427a35" },
        :vlan => { :trunk => false } }
    ]
  end

  def network_all_dns
    {
      :enable => true, :forward_plain_names => false,
      :forwarders => [{ :addr => "192.168.20.30", :port => 53 },
                      { :addr => "192.168.20.50" },
                      { :domain => "example.com" }],
      :hosts => [{ :ip => "192.168.20.70", :hostnames => ["ns1.example.com", "ns1"] }],
      :txts => [{ :name => "example", :value => "text" }],
      :srvs => [{ :service => "xmpp", :protocol => "tcp", :domain => "example.com",
                  :target => "xmpp.example.com", :port => 5269, :priority => 10, :weight => 100 }]
    }
  end

  def network_all_ips
    [
      {
        :address => "172.16.200.1", :netmask => "255.255.252.0", :local_ptr => true,
        :tftp => "/var/lib/tftpboot",
        :dhcp => {
          :ranges => [{ :start => "172.16.201.50", :end => "172.16.202.100" },
                      { :start => "172.16.202.200", :end => "172.16.202.250" }],
          :hosts => [{ :mac => "44:11:bb:33:dd:22", :name => "hostnm", :ip => "172.16.200.60", :lease => { :expiry => 24, :unit => "hours" } }],
          :bootp => { :file => "pxelinux.0", :server => "172.16.200.10" }
        }
      },
      {
        :address => "2001:db8::1", :prefix => 100, :family => "ipv6",
        :dhcp => { :hosts => [{ :id => "00:02:00:00:ab:11:b0:42:16:54:60:57:e8:65", :name => "ipv6host", :ip => "2001:db8::0100" }] }
      }
    ]
  end

  def unmanaged_elements_xml
    <<~XML
      <?xml version="1.0"?>
      <network xmlns:dnsmasq="http://libvirt.org/schemas/network/dnsmasq/1.0" xmlns:something="http://something.example.org">
        <unknown_element attr="value">
          <something:interesting/>
        </unknown_element>
        <vendor:specific xmlns:vendor="http://example.com">stuff</vendor:specific>
        <name>fog-test-xml</name>
        <uuid>106c3ca9-04ca-4120-a9a5-c153e41289d9</uuid>
        <ip address="2001:db8::1" prefix="100" family="ipv6">
          <dhcp>
            <host id="00:02:00:00:ab:11:b0:42:16:54:60:57:e8:65" name="ipv6host" ip="2001:db8::0100"/>
          </dhcp>
        </ip>
      </network>
    XML
  end

  def test_xml
    attrs = network_all_attrs
    network = @compute.networks.new(attrs)
    expected_attrs = JSON.parse(network.send(:defaults).merge(attrs).to_json)

    assert_equal expected_attrs, JSON.parse(network.to_json)

    network_xml = network.to_xml
    parsed_network = Fog::Libvirt::Compute::Network.new(Fog::Libvirt::Compute::Network.parse_xml(network_xml))

    assert_equal network_xml.strip, "<?xml version=\"1.0\"?>\n#{parsed_network.xml}"
    assert_equal expected_attrs, JSON.parse(parsed_network.to_json)

    assert_equal unmanaged_elements_xml, unmanaged_elements_network(parsed_network.xml).to_xml
  end

  def unmanaged_elements_network(xml)
    network_element = Nokogiri::XML(xml).at_xpath("//network")
    network_element.add_namespace("something", "http://something.example.org")
    network_element.add_child('<unknown_element attr="value"><something:interesting /></unknown_element>')
    network_element.add_child('<vendor:specific xmlns:vendor="http://example.com">stuff</vendor:specific>')

    attrs = network_all_attrs
    custom_attrs = attrs.merge(Fog::Libvirt::Util.hash_except(attrs, :uuid, :name, :ips).transform_values { nil })
    custom_attrs[:ips] = [attrs[:ips].last]
    custom_attrs[:xml] = network_element.to_xml
    @compute.networks.new(custom_attrs)
  end

  def test_defaults
    network = @compute.networks.new(:name => __method__.to_s)
    refute network.active?
    refute network.autostart?
    assert network.persistent?
  end

  def test_clone_dup
    attrs = network_all_attrs
    attrs[:active] = true
    attrs[:xml] = unmanaged_elements_xml
    attrs[:preloaded] = true
    network = @compute.networks.new(attrs)
    refute_nil network.instance_variable_get(:@saved_attributes)

    network_clone = network.clone
    network_check_clone(network_clone, network, attrs)
    network_check_deep_clone(network_clone, network, attrs)

    network_dup = network_clone.dup
    network_check_dup(network_dup, network_clone)
    network_check_deep_dup(network_dup, network_clone)

    assert_equal unmanaged_elements_xml, network_dup.xml
  end

  def network_check_clone(network_clone, network, attrs)
    refute_same network, network_clone
    assert_kind_of Fog::Libvirt::Compute::Network, network_clone

    assert_equal network.uuid, network_clone.uuid
    assert_equal network.name, network_clone.name
    assert network_clone.active?
  end

  def network_check_deep_clone(network_clone, network, attrs)
    network_clone.ips[0].dhcp.hosts[0].name = "new name for clone"
    assert_equal attrs[:ips][0][:dhcp][:hosts][0][:name], network.ips[0].dhcp.hosts[0].name

    network_clone.dns.forwarders.pop
    assert network.dns.forwarders.length > network_clone.dns.forwarders.length
  end

  def network_check_dup(network_dup, network_clone)
    refute_same network_clone, network_dup
    assert_kind_of Fog::Libvirt::Compute::Network, network_dup

    assert_nil network_dup.uuid
    refute_equal network_clone.name, network_dup.name
    assert_equal network_clone.persistent, network_dup.persistent
    assert_nil network_dup.instance_variable_get(:@saved_attributes)
    refute network_dup.active?
  end

  def network_check_deep_dup(network_dup, network_clone)
    assert_equal network_clone.ips[0].dhcp.hosts[0].name, network_dup.ips[0].dhcp.hosts[0].name
    network_dup.ips[0].dhcp.hosts[0].name = "name for dup"

    refute_equal network_clone.ips[0].dhcp.hosts[0].name, network_dup.ips[0].dhcp.hosts[0].name
  end

  def test_lifecycle
    network = create_network(__method__, :forward => { :mode => :bridge }, :persistent => false)

    lifecycle_transient_shutdown(network)
    lifecycle_make_persistent(network)
    lifecycle_autostart(network)
    lifecycle_recreate_persistent(network)
    lifecycle_persistent_shutdown(network)
  end

  def lifecycle_transient_shutdown(network)
    assert network.active?
    refute network.persistent?
    refute network.autostart?
    network.shutdown
    assert_nil network.uuid
    refute network.active?
    refute network.persistent?
  end

  def lifecycle_make_persistent(network)
    network.active = false
    network.persistent = true

    assert_save network, 1, 0, :active, :persistent, :autostart

    refute network.active?
    assert network.persistent?
  end

  def lifecycle_autostart(network)
    network.start
    assert network.active?
    assert network.persistent?

    network.active = false
    network.autostart = true

    assert_save network, 0, 0, :active, :persistent, :autostart

    refute network.active?
    assert network.persistent?
    assert network.autostart?

    network.active = true
    network.persistent = false

    assert_save network, 1, 0, :persistent

    assert network.active?
    refute network.persistent?
    refute network.autostart?

    network.active = false

    assert_save network, 0, 0, :persistent

    assert network.active?
    refute network.persistent?
    refute network.autostart?
  end

  def lifecycle_recreate_persistent(network)
    network.start
    network.destroy
    refute network.active?
    refute network.persistent?
    refute network.autostart?
    assert_nil network.uuid

    network.active = false
    network.persistent = true

    assert_save network, 1, 0, :active, :persistent, :autostart

    refute network.active?
    assert network.persistent?
  end

  def lifecycle_persistent_shutdown(network)
    network.active = true

    assert_save network, 0, 0, :active, :persistent, :autostart

    assert network.active?
    assert network.persistent?

    network.shutdown
    refute_nil network.uuid
  end

  def test_various
    network = create_network(__method__)

    various_initial(network)
    various_other(network)
    various_empty(network)
    various_dnsmasq(network)
  end

  def various_initial(network)
    refute network.autostart?

    network.enable_autostart
    network.domain = "example.com"

    network.bridge = nil
    network.bridge_name = "bridge-test1"
    network.routes = "192.168.70.20"
    network.routes[0].address = "192.168.50.0"
    network.routes[0].netmask = "255.255.255.0"
    network.forward.nat = Fog::Libvirt::Compute::Network::Nat.new
    network.forward.nat.address = IPAddr.new("192.168.100.1")..IPAddr.new("192.168.100.10")
    network.forward.nat.port = 5000..6000

    assert network.autostart?

    assert_save network, 1, 0, :domain, :routes, :forward
    assert_equal "bridge-test1", network.bridge_name

    network.disable_autostart
    refute network.autostart?
  end

  def various_other(network)
    network.bridge = "bridge-test2"
    network.forward.nat.address = IPAddr.new("10.50.70.1")...IPAddr.new("10.50.70.255")
    network.forward.nat.port = 1000...2000

    assert_save network, 1, 0, :domain, :routes, :forward
    assert_equal "bridge-test2", network.bridge_name

    network.forward = "route"
    assert_save network, 1, 0, :routes, :forward
  end

  def various_empty(network)
    network.dns = Fog::Libvirt::Compute::Network::Dns.new
    network.bandwidth = Fog::Libvirt::Compute::Network::Bandwidth.new
    assert_save network, 0, 0, :domain, :routes, :forward, :dns, :bandwidth
  end

  def various_dnsmasq(network)
    # libvirt test driver doesn't support dnsmasq
    # so we can only test this against actual libvirt
    real_libvirt = !Fog.mock? && real_libvirt?

    network.dnsmasq = "custom=option"
    assert_save network, 1, 0, real_libvirt ? :dnsmasq : nil

    network.dnsmasq = ["more=options", "another=123"]
    assert_save network, 1, 0, real_libvirt ? :dnsmasq : nil
  end

  def forward_bridge_final_xml
    <<~XML
      <?xml version="1.0"?>
      <network>
        <name>fog-test-forward-bridge</name>
        <forward mode="bridge"/>
      </network>
    XML
  end

  def test_forward_bridge
    network = create_network(__method__, :forward => { :mode => :bridge, :interfaces => "eth0" })
    network.forward.dev = "eth1"
    network.forward.interfaces += ["eth0", "eth2"]

    assert_save network, 0, 4, :forward, &method(:forward_bridge_assert_initial_updates)
    assert network.xml.include?('<forward dev="eth1"')

    network.forward.interfaces[2] = "eth7"
    assert_save network, 0, 2, :forward, &method(:forward_bridge_assert_modify_updates)
    assert network.xml.include?('<forward dev="eth1"')

    network.forward.dev = nil
    assert_save network, 0, 3, :forward, &method(:forward_bridge_assert_clear_updates)

    assert_equal forward_bridge_final_xml, remove_uuid(network.to_xml)
  end

  def forward_bridge_assert_initial_updates(calls)
    assert_update_section_call calls, 0, :delete, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth0"/>\n)
    assert_update_section_call calls, 1, :add_last, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth1"/>\n)
    assert_update_section_call calls, 2, :add_last, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth0"/>\n)
    assert_update_section_call calls, 3, :add_last, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth2"/>\n)
  end

  def forward_bridge_assert_modify_updates(calls)
    assert_update_section_call calls, 0, :delete, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth2"/>\n)
    assert_update_section_call calls, 1, :add_last, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth7"/>\n)
  end

  def forward_bridge_assert_clear_updates(calls)
    assert_update_section_call calls, 0, :delete, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth1"/>\n)
    assert_update_section_call calls, 1, :delete, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth0"/>\n)
    assert_update_section_call calls, 2, :delete, :forward_interface, %(<?xml version="1.0"?>\n<interface dev="eth7"/>\n)
  end

  def test_portgroups
    network = create_network(:test_portgroups,
                             :forward => { :mode => :bridge },
                             :portgroups => [
                               { :name => "portgroup1",
                                 :trust_guest_rx_filters => true,
                                 :virtualport => {
                                   :interfaceid => "aabbccdd-ffa7-40c8-83ad-b8d47ba270f3"
                                 } },
                               { :name => "portgroup2" }
                             ],
                             :persistent => false)

    portgroups_live(network)
    portgroups_persistent_live(network)
    portgroups_persistent(network)
    portgroups_final(network)
  end

  def portgroups_live(network)
    assert network.active?
    refute network.persistent?

    network.portgroups = network.portgroups.drop(1)
    network.portgroups[0].vlan = { :trunk => true, :tags => 20 }
    network.portgroups << { :name => "portgroup3", :default => true, :virtualport => { :type => "802.1Qbh", :profileid => "port-profile" } }

    assert_save network, 0, 3, :portgroups do |calls|
      assert_update_section_call calls, 0, :modify, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup2">\n  <vlan trunk="yes">\n    <tag id="20"/>\n  </vlan>\n</portgroup>\n), :persist => false, :live => true
      assert_update_section_call calls, 1, :delete, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup1" trustGuestRxFilters="yes">\n  <virtualport>\n    <parameters interfaceid="aabbccdd-ffa7-40c8-83ad-b8d47ba270f3"/>\n  </virtualport>\n</portgroup>\n), :persist => false, :live => true
      assert_update_section_call calls, 2, :add_last, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup3" default="yes">\n  <virtualport type="802.1Qbh">\n    <parameters profileid="port-profile"/>\n  </virtualport>\n</portgroup>\n), :persist => false, :live => true
    end
  end

  def portgroups_first_xml
    <<~XML
      <?xml version="1.0"?>
      <network>
        <name>fog-test-portgroups</name>
        <forward mode="bridge"/>
        <portgroup name="portgroup2">
          <vlan>
            <tag id="20"/>
          </vlan>
        </portgroup>
      </network>
    XML
  end

  def portgroups_persistent_live(network)
    network.persistent = true
    network.save
    assert network.active?
    assert network.persistent?

    network.portgroups.pop
    network.portgroups[0].vlan.trunk = nil
    assert_save network, 0, 2, :portgroups do |calls|
      assert_update_section_call calls, 0, :modify, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup2">\n  <vlan>\n    <tag id="20"/>\n  </vlan>\n</portgroup>\n), :persist => true, :live => true
      assert_update_section_call calls, 1, :delete, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup3" default="yes">\n  <virtualport type="802.1Qbh">\n    <parameters profileid="port-profile"/>\n  </virtualport>\n</portgroup>\n), :persist => true, :live => true
    end

    assert_equal portgroups_first_xml, remove_uuid(@compute.networks.get(network.uuid).to_xml)
  end

  def portgroups_persistent(network)
    network.shutdown
    refute network.active?
    assert network.persistent?
    assert_equal portgroups_first_xml, remove_uuid(@compute.networks.get(network.uuid).to_xml)

    network.portgroups[0].vlan.trunk = true
    network.portgroups[0].vlan.tags << 50

    assert_save network, 0, 1, :portgroups do |calls|
      assert_update_section_call calls, 0, :modify, :portgroup, %(<?xml version="1.0"?>\n<portgroup name="portgroup2">\n  <vlan trunk="yes">\n    <tag id="20"/>\n    <tag id="50"/>\n  </vlan>\n</portgroup>\n), :persist => true, :live => false
    end
  end

  def portgroups_final_xml
    <<~XML
      <?xml version="1.0"?>
      <network>
        <name>fog-test-portgroups</name>
        <bridge name="virbr-fog-test-portgroups" stp="on" delay="0"/>
        <mac address="e4:bd:de:c5:aa:cc"/>
        <portgroup name="final-portgroup">
          <bandwidth>
            <inbound average="500"/>
            <outbound average="300"/>
          </bandwidth>
        </portgroup>
      </network>
    XML
  end

  def portgroups_final(network)
    network.forward = nil
    network.bridge_name = "virbr-fog-test-portgroups"
    network.mac = "e4:bd:de:c5:aa:cc"
    network.portgroups = { :name => "final-portgroup", :bandwidth => { :inbound => 500, :outbound => "300" } }

    assert_save network, 1, 0, :portgroups
    assert_equal portgroups_final_xml, remove_uuid(@compute.networks.get(network.uuid).to_xml)
  end

  def dns_attrs
    {
      :hosts => [{ :ip => "172.16.160.25", :hostnames => ["hostname1.local"] },
                 { :ip => "172.16.170.85", :hostnames => ["hostname2.test", "hostname22.local"] }],
      :txts => [{ :name => "txt1", :value => "value1" },
                { :name => "txt2", :value => "value2" }],
      :srvs => [{ :service => "sip", :protocol => "tcp", :domain => "example.com",
                  :target => "sip.example.com", :port => 5060, :priority => 10, :weight => 100 },
                { :service => "smtp", :protocol => "tcp", :domain => "example.com",
                  :target => "smtp.example.com", :port => 25, :priority => 20, :weight => 200 }]
    }
  end

  def test_dns
    network = create_network(__method__, :dns => dns_attrs)

    dns_initial_updates(network)

    network.dns = nil
    assert_save network, 0, 6, &method(:dns_assert_clear_updates)

    network.dns = { :txts => { :name => "fresh", :value => "456" } }
    assert_save network, 0, 1, :dns do |calls|
      assert_update_section_call calls, 0, :add_last, :dns_txt, %(<?xml version="1.0"?>\n<txt name="fresh" value="456"/>\n)
    end

    network.dns = { :forwarders => ["192.168.120.130"] }
    assert_save network, 1, 0, :dns
  end

  def dns_initial_updates(network)
    dns_initial_remove(network)
    dns_initial_add(network)
    dns_initial_modify(network)

    expected_section_updates = [10, 12]
    expected_asserts = [:dns_assert_modify_updates, :dns_assert_nomodify_updates]

    # DNS host/txt :modify supported since libvirt >= 10.6.0
    if @compute.client.libversion >= 10_006_000
      mocked_version = 10_005_000
    else
      expected_section_updates.reverse!
      expected_asserts.reverse!
      mocked_version = 10_006_000
    end

    network_copy = network.clone
    assert_save network, 0, expected_section_updates.first, :dns, &method(expected_asserts.first)

    # Now test other case by mocking it
    @compute.client.expects(:libversion).returns(mocked_version).twice
    assert_save network_copy, 0, expected_section_updates.last, :dns, :mock_calls => true, &method(expected_asserts.last)

    assert network.models_equal?(network_copy, network)
  ensure
    @compute.client.unstub(:libversion)
  end

  def dns_initial_remove(network)
    network.dns.hosts = network.dns.hosts.drop(1)
    network.dns.txts = network.dns.txts.drop(1)
    network.dns.srvs = network.dns.srvs.drop(1)
  end

  def dns_initial_add(network)
    network.dns.hosts << { :ip => "172.16.164.51", :hostnames => ["added.example.org"] }
    network.dns.txts << { :name => "added", :value => "added value" }
    network.dns.srvs << { :service => "pop3", :protocol => "tcp", :target => "pop3.example.org" }
  end

  def dns_initial_modify(network)
    network.dns.hosts[0].hostnames = ["hostname2-replaced.test"]
    network.dns.txts[0].value = "new value"
    network.dns.srvs[0].priority = 50
  end

  # When libvirt supports DNS host/txt :modify (>= 10.6.0)
  def dns_assert_modify_updates(calls)
    assert_update_section_call calls, 0, :modify, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.170.85">\n  <hostname>hostname2-replaced.test</hostname>\n</host>\n)
    assert_update_section_call calls, 1, :delete, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.160.25">\n  <hostname>hostname1.local</hostname>\n</host>\n)
    assert_update_section_call calls, 2, :add_last, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.164.51">\n  <hostname>added.example.org</hostname>\n</host>\n)
    assert_update_section_call calls, 3, :modify, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt2" value="new value"/>\n)
    assert_update_section_call calls, 4, :delete, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt1" value="value1"/>\n)
    assert_update_section_call calls, 5, :add_last, :dns_txt, %(<?xml version="1.0"?>\n<txt name="added" value="added value"/>\n)
    assert_update_section_call calls, 6, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="sip" protocol="tcp" domain="example.com" target="sip.example.com" port="5060" priority="10" weight="100"/>\n)
    assert_update_section_call calls, 7, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="smtp" protocol="tcp" domain="example.com" target="smtp.example.com" port="25" priority="20" weight="200"/>\n)
    assert_update_section_call calls, 8, :add_last, :dns_srv, %(<?xml version="1.0"?>\n<srv service="smtp" protocol="tcp" domain="example.com" target="smtp.example.com" port="25" priority="50" weight="200"/>\n)
    assert_update_section_call calls, 9, :add_last, :dns_srv, %(<?xml version="1.0"?>\n<srv service="pop3" protocol="tcp" target="pop3.example.org"/>\n)
  end

  # When libvirt doesn't support DNS host/txt :modify (< 10.6.0)
  def dns_assert_nomodify_updates(calls)
    assert_update_section_call calls, 0, :delete, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.160.25">\n  <hostname>hostname1.local</hostname>\n</host>\n)
    assert_update_section_call calls, 1, :delete, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.170.85">\n  <hostname>hostname2.test</hostname>\n  <hostname>hostname22.local</hostname>\n</host>\n)
    assert_update_section_call calls, 2, :add_last, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.170.85">\n  <hostname>hostname2-replaced.test</hostname>\n</host>\n)
    assert_update_section_call calls, 3, :add_last, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.164.51">\n  <hostname>added.example.org</hostname>\n</host>\n)
    assert_update_section_call calls, 4, :delete, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt1" value="value1"/>\n)
    assert_update_section_call calls, 5, :delete, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt2" value="value2"/>\n)
    assert_update_section_call calls, 6, :add_last, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt2" value="new value"/>\n)
    assert_update_section_call calls, 7, :add_last, :dns_txt, %(<?xml version="1.0"?>\n<txt name="added" value="added value"/>\n)
    assert_update_section_call calls, 8, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="sip" protocol="tcp" domain="example.com" target="sip.example.com" port="5060" priority="10" weight="100"/>\n)
    assert_update_section_call calls, 9, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="smtp" protocol="tcp" domain="example.com" target="smtp.example.com" port="25" priority="20" weight="200"/>\n)
    assert_update_section_call calls, 10, :add_last, :dns_srv, %(<?xml version="1.0"?>\n<srv service="smtp" protocol="tcp" domain="example.com" target="smtp.example.com" port="25" priority="50" weight="200"/>\n)
    assert_update_section_call calls, 11, :add_last, :dns_srv, %(<?xml version="1.0"?>\n<srv service="pop3" protocol="tcp" target="pop3.example.org"/>\n)
  end

  def dns_assert_clear_updates(calls)
    assert_update_section_call calls, 0, :delete, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.170.85">\n  <hostname>hostname2-replaced.test</hostname>\n</host>\n)
    assert_update_section_call calls, 1, :delete, :dns_host, %(<?xml version="1.0"?>\n<host ip="172.16.164.51">\n  <hostname>added.example.org</hostname>\n</host>\n)
    assert_update_section_call calls, 2, :delete, :dns_txt, %(<?xml version="1.0"?>\n<txt name="txt2" value="new value"/>\n)
    assert_update_section_call calls, 3, :delete, :dns_txt, %(<?xml version="1.0"?>\n<txt name="added" value="added value"/>\n)
    assert_update_section_call calls, 4, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="smtp" protocol="tcp" domain="example.com" target="smtp.example.com" port="25" priority="50" weight="200"/>\n)
    assert_update_section_call calls, 5, :delete, :dns_srv, %(<?xml version="1.0"?>\n<srv service="pop3" protocol="tcp" target="pop3.example.org"/>\n)
  end

  def ips_expected_xml
    <<~XML
      <?xml version="1.0"?>
      <network>
        <name>fog-test-ips</name>
        <forward mode="nat"/>
        <bridge name="virbr-fog-test" stp="on" delay="0"/>
        <mac address="cc:ee:f0:d7:b1:54"/>
        <ip address="172.16.160.27" prefix="22" localPtr="yes"/>
        <ip family="ipv6" address="2001:db8::a300" prefix="100"/>
        <ip address="172.16.248.1" netmask="255.255.252.0"/>
        <ip family="ipv6" address="2001:db8::eeee:7000" prefix="112"/>
      </network>
    XML
  end

  def test_ips
    network = create_network(__method__, :ips => [
                               "172.16.140.1",
                               { :address => "172.16.160.2", :prefix => 22, :local_ptr => true },
                               { :address => "172.16.220.3", :netmask => "255.255.252.0" }
                             ])

    ips_initial_updates(network)
    ips_next_updates(network)

    network.ips = Fog::Libvirt::Compute::Network::Ip.new(:address => "172.16.150.12", :netmask => "255.255.224.0")
    assert_save network, 1, 0, :ips
  end

  def ips_initial_updates(network)
    network.ips = network.ips.drop(1)
    network.ips[0].address = "172.16.160.27"
    network.ips << { :address => "172.16.248.1", :netmask => "255.255.252.0" }
    assert_save network, 1, 0, :ips
  end

  def ips_next_updates(network)
    network.ips[1].address = "2001:db8::a300"
    network.ips[1].netmask = nil
    network.ips[1].prefix = 100
    network.ips[1].family = :ipv6
    network.ips << { :address => "2001:db8::eeee:7000", :prefix => 112, :family => :ipv6 }

    assert_save network, 1, 0, :ips
    assert_equal ips_expected_xml, remove_uuid(network.to_xml)
  end

  def dhcp_network_ips
    [
      {
        :address => "192.168.96.1", :netmask => "255.255.224.0",
        :dhcp => {
          :ranges => [{ :start => "192.168.96.40", :end => "192.168.96.80" },
                      "192.168.96.150".."192.168.96.200"],
          :hosts => [{ :mac => "a2:bb:cc:dd:aa:01", :name => "host1", :ip => "192.168.96.17" },
                     { :mac => "b4:aa:77:cc:ee:02", :name => "host2", :ip => "192.168.96.24" }]
        }
      },
      {
        :address => "2001:db8::dcea:1000", :prefix => 97, :family => :ipv6,
        :dhcp => {
          :ranges => [{ :start => "2001:db8::dcea:3000", :end => "2001:db8::dcea:5000" },
                      IPAddr.new("2001:db8::dcea:8000")...IPAddr.new("2001:db8::dcea:9000")],
          :hosts => [{ :id => "00:02:00:00:bb:cc:dd:ee:16:54:60:57:aa:21", :ip => "2001:db8::dcea:2100" },
                     { :id => "00:02:00:00:ee:ff:aa:bb:21:23:24:25:26:32", :ip => "2001:db8::dcea:6200" }]
        }
      }
    ]
  end

  def dhcp_final_xml
    <<~XML
      <?xml version="1.0"?>
      <network>
        <name>fog-test-dhcp</name>
        <forward mode="nat"/>
        <bridge name="virbr-fog-test" stp="on" delay="0"/>
        <mac address="cc:ee:f0:d7:b1:54"/>
        <ip address="192.168.96.1" netmask="255.255.224.0">
          <dhcp>
            <range start="192.168.96.150" end="192.168.96.200">
              <lease expiry="9600" unit="seconds"/>
            </range>
            <range start="192.168.96.230" end="192.168.96.250"/>
            <host mac="b4:aa:77:cc:ee:02" name="updated_host" ip="192.168.96.24"/>
            <host mac="cc:aa:ee:ff:bb:03" name="host3" ip="192.168.96.36"/>
            <bootp file="grub.efi"/>
          </dhcp>
        </ip>
        <ip family="ipv6" address="2001:db8::dcea:1000" prefix="97">
          <dhcp>
            <range start="2001:db8::dcea:1200" end="2001:db8::dcea:1400"/>
          </dhcp>
        </ip>
      </network>
    XML
  end

  def test_dhcp
    network = create_network(__method__, :ips => dhcp_network_ips)

    dhcp_initial_updates(network)

    network.ips[1].dhcp = nil
    assert_save network, 0, 4, :ips, &method(:dhcp_assert_clear_updates)

    network.ips[1].dhcp = { :ranges => [{ :start => "2001:db8::dcea:1200", :end => "2001:db8::dcea:1400" }] }
    assert_save network, 0, 1, :ips do |calls|
      assert_update_section_call calls, 0, :add_last, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:1200" end="2001:db8::dcea:1400"/>\n), :parent_index => 1
    end

    network.ips[0].dhcp.bootp = "grub.efi"
    assert_save network, 1, 0, :ips

    assert_equal dhcp_final_xml, remove_uuid(network.to_xml)
  end

  def dhcp_initial_updates(network)
    dhcp_change_ipv4(network.ips[0].dhcp)
    dhcp_change_ipv6(network.ips[1].dhcp)

    assert_save network, 0, 14, :ips, &method(:dhcp_assert_updates)
  end

  def dhcp_change_ipv4(dhcp)
    dhcp.ranges = dhcp.ranges.drop(1)
    dhcp.hosts = dhcp.hosts.drop(1)
    dhcp.ranges << { :start => IPAddr.new("192.168.96.230"), :end => IPAddr.new("192.168.96.250") }
    dhcp.hosts << { :mac => "cc:aa:ee:ff:bb:03", :name => "host3", :ip => "192.168.96.36" }
    dhcp.ranges[0].lease = { :expiry => 9600, "unit" => :seconds }
    dhcp.hosts[0].name = "updated_host"
  end

  def dhcp_change_ipv6(dhcp)
    dhcp.ranges = dhcp.ranges.drop(1)
    dhcp.hosts = dhcp.hosts.drop(1)
    dhcp.ranges << { :start => "2001:db8::dcea:a000", :end => "2001:db8::dcea:b000" }
    dhcp.hosts << { :id => "00:02:00:00:cc:dd:ee:ff:32:34:36:38:40:43", :ip => "2001:db8::dcea:1400" }
    dhcp.ranges[0].lease = 20
    dhcp.ranges[0].lease.unit = "hours"
    dhcp.hosts[0].id = "00:02:00:00:dd:ee:cc:ff:66:77:88:99:00:55"
  end

  def dhcp_assert_updates(calls)
    assert_update_section_call calls, 0, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="192.168.96.40" end="192.168.96.80"/>\n), :parent_index => 0
    assert_update_section_call calls, 1, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="192.168.96.150" end="192.168.96.200"/>\n), :parent_index => 0
    assert_update_section_call calls, 2, :add_last, :dhcp_range, %(<?xml version="1.0"?>\n<range start="192.168.96.150" end="192.168.96.200">\n  <lease expiry="9600" unit="seconds"/>\n</range>\n), :parent_index => 0
    assert_update_section_call calls, 3, :add_last, :dhcp_range, %(<?xml version="1.0"?>\n<range start="192.168.96.230" end="192.168.96.250"/>\n), :parent_index => 0
    assert_update_section_call calls, 4, :modify, :dhcp_host, %(<?xml version="1.0"?>\n<host mac="b4:aa:77:cc:ee:02" name="updated_host" ip="192.168.96.24"/>\n), :parent_index => 0
    assert_update_section_call calls, 5, :delete, :dhcp_host, %(<?xml version="1.0"?>\n<host mac="a2:bb:cc:dd:aa:01" name="host1" ip="192.168.96.17"/>\n), :parent_index => 0
    assert_update_section_call calls, 6, :add_last, :dhcp_host, %(<?xml version="1.0"?>\n<host mac="cc:aa:ee:ff:bb:03" name="host3" ip="192.168.96.36"/>\n), :parent_index => 0

    assert_update_section_call calls, 7, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:3000" end="2001:db8::dcea:5000"/>\n), :parent_index => 1
    assert_update_section_call calls, 8, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:8000" end="2001:db8::dcea:8fff"/>\n), :parent_index => 1
    assert_update_section_call calls, 9, :add_last, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:8000" end="2001:db8::dcea:8fff">\n  <lease expiry="20" unit="hours"/>\n</range>\n), :parent_index => 1
    assert_update_section_call calls, 10, :add_last, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:a000" end="2001:db8::dcea:b000"/>\n), :parent_index => 1
    assert_update_section_call calls, 11, :modify, :dhcp_host, %(<?xml version="1.0"?>\n<host id="00:02:00:00:dd:ee:cc:ff:66:77:88:99:00:55" ip="2001:db8::dcea:6200"/>\n), :parent_index => 1
    assert_update_section_call calls, 12, :delete, :dhcp_host, %(<?xml version="1.0"?>\n<host id="00:02:00:00:bb:cc:dd:ee:16:54:60:57:aa:21" ip="2001:db8::dcea:2100"/>\n), :parent_index => 1
    assert_update_section_call calls, 13, :add_last, :dhcp_host, %(<?xml version="1.0"?>\n<host id="00:02:00:00:cc:dd:ee:ff:32:34:36:38:40:43" ip="2001:db8::dcea:1400"/>\n), :parent_index => 1
  end

  def dhcp_assert_clear_updates(calls)
    assert_update_section_call calls, 0, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:8000" end="2001:db8::dcea:8fff">\n  <lease expiry="20" unit="hours"/>\n</range>\n), :parent_index => 1
    assert_update_section_call calls, 1, :delete, :dhcp_range, %(<?xml version="1.0"?>\n<range start="2001:db8::dcea:a000" end="2001:db8::dcea:b000"/>\n), :parent_index => 1
    assert_update_section_call calls, 2, :delete, :dhcp_host, %(<?xml version="1.0"?>\n<host id="00:02:00:00:dd:ee:cc:ff:66:77:88:99:00:55" ip="2001:db8::dcea:6200"/>\n), :parent_index => 1
    assert_update_section_call calls, 3, :delete, :dhcp_host, %(<?xml version="1.0"?>\n<host id="00:02:00:00:cc:dd:ee:ff:32:34:36:38:40:43" ip="2001:db8::dcea:1400"/>\n), :parent_index => 1
  end

  def test_rename
    network = create_network(__method__)

    old_name = network.name
    network.name = "fog-test-rename-new-name"
    assert_save network, 1, 0, :uuid, :name
    @created_networks.delete(old_name)
    @created_networks << network.name

    old_uuid = network.uuid
    network.uuid = "22222222-3333-4444-5555-666666666666"
    assert_save network, 1, 0, :uuid, :name
    assert_equal "22222222-3333-4444-5555-666666666666", network.uuid
    assert_raises(Libvirt::RetrieveError) { @compute.client.lookup_network_by_uuid(old_uuid) }
  end

  private

  def remove_uuid(xml)
    xml.gsub(/^\s*<uuid>[^\n]*\n/, "")
  end

  def assert_save(network, expected_full_updates, expected_section_updates, *check_attrs, mock_calls: false)
    full_update_calls = []
    section_update_calls = []

    real_update_network = network.service.method(:update_network)
    real_update_network_section = network.service.method(:update_network_section)

    network.service.define_singleton_method(:update_network) do |*args|
      full_update_calls << args
      real_update_network.call(*args) unless mock_calls
    end
    network.service.define_singleton_method(:update_network_section) do |*args|
      section_update_calls << args
      real_update_network_section.call(*args) unless mock_calls
    end

    before_save = JSON.parse(network.clone.to_json)

    network.save

    assert_equal expected_full_updates, full_update_calls.length, "full update count"
    assert_equal expected_section_updates, section_update_calls.length, "section update count"

    after_save = JSON.parse(@compute.networks.get(network.uuid).to_json)
    assert_saved_attrs(before_save, after_save, check_attrs)

    yield section_update_calls if block_given?
  ensure
    network.service.singleton_class.remove_method(:update_network)
    network.service.singleton_class.remove_method(:update_network_section)
  end

  def assert_update_section_call(section_update_calls, index, command, section, xml, parent_index: -1, persist: true, live: false) # rubocop:disable Metrics/ParameterLists
    assert_equal [command, section, xml, { :parent_index => parent_index, :persist => persist, :live => live }], section_update_calls[index].drop(1)
  end

  def create_network(name, options = {})
    options[:name] = "fog-#{name.to_s.gsub('_', '-')}"
    options[:forward] = { :mode => :nat } unless options[:forward]
    if options[:forward][:mode] == :nat
      options[:mac] = "cc:ee:f0:d7:b1:54" unless options.key?(:mac)
      options[:bridge] = { :name => "virbr-fog-test", :stp => true, :delay => 0 } if !options[:bridge] && !options[:bridge_name]
      options[:ips] = [{ :address => "192.168.70.1", :netmask => "255.255.255.0" }] unless options[:ips]
    end
    network = @compute.networks.new(options)
    network.save
    @created_networks << network.name
    network
  end

  def assert_saved_attrs(before_save, after_save, check_attrs)
    check_attrs.each do |attr|
      expected = remove_empty(before_save[attr.to_s])
      if expected.nil?
        assert_nil after_save[attr.to_s]
      else
        assert_equal expected, after_save[attr.to_s]
      end
    end
  end

  def remove_empty(attrs)
    return attrs unless attrs

    if attrs.is_a?(Array)
      attrs = attrs.map { |attr| remove_empty(attr) }.compact
      attrs = nil if attrs.empty?
    elsif attrs.is_a?(Hash)
      attrs = attrs.transform_values { |value| remove_empty(value) }.compact
      attrs = nil if attrs.empty?
    end
    attrs
  end
end
