require_relative "../test_helper"

class NetworkTest < Minitest::Test
  def setup
    @network = Fog::Compute[:libvirt].networks.new(:name => "default", :uuid => "dd8fe884-6c02-601e-7551-cca97df1c5df", :bridge_name => "virbr0")
  end

  def test_model
    assert_kind_of Fog::Libvirt::Compute::Network, @network

    assert @network.respond_to? "reload"
    assert @network.respond_to? "dhcp_leases"

    assert_kind_of Array, @network.dhcp_leases("aa:bb:cc:dd:ee:ff", 0) if Fog.mock?

    attributes = [:name, :uuid, :bridge_name]
    attributes.each do |attribute|
      assert @network.respond_to? attribute
      assert @network.attributes.key? attribute
    end
  end

  def test_to_xml
    expected = <<~NETWORK
      <?xml version="1.0"?>
      <network>
        <name>default</name>
        <bridge name="virbr0" stp="on" delay="0"/>
      </network>
    NETWORK
    assert_equal expected, @network.to_xml
  end
end
