require File.expand_path("../../../helper", __dir__)
require "fog/libvirt"

class DetachIsoFakeDomain
  attr_reader :xml, :flags, :update_xml, :update_flags, :calls

  def initialize(active: false, fail_detach: false)
    @active = active
    @fail_detach = fail_detach
    @calls = []
  end

  def active?
    @active
  end

  def update_device(xml, flags = 0)
    @calls << :update
    @update_xml = xml
    @update_flags = flags
    true
  end

  def detach_device(xml, flags = 0)
    raise ::Libvirt::Error, "detach not supported" if @fail_detach

    @calls << :detach
    @xml = xml
    @flags = flags
    true
  end
end

class DetachIsoFakeClient
  def initialize(domain)
    @domain = domain
  end

  def lookup_domain_by_uuid(_uuid)
    @domain
  end
end

Shindo.tests("Fog::Compute[:libvirt] | detach_iso") do
  tests("detach_iso") do
    returns(true, "detaches a cdrom device via libvirt detach_device") do
      domain = DetachIsoFakeDomain.new(:active => false)
      client = DetachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      ok = service.detach_iso(uuid, :target_dev => "sdc", :bus => "sata", :flags => 0)

      ok &&
        domain.calls == [:detach] &&
        domain.xml.include?('device="cdrom"') &&
        domain.xml.include?('type="file"') &&
        domain.xml.include?('dev="sdc"') &&
        domain.xml.include?('bus="sata"') &&
        domain.flags.zero?
    end

    returns(true, "uses AFFECT_LIVE and AFFECT_CONFIG for active domains by default") do
      domain = DetachIsoFakeDomain.new(:active => true)
      client = DetachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"

      ok = service.detach_iso(uuid)

      ok &&
        domain.calls == [:update, :detach] &&
        domain.update_xml.include?('tray="open"') &&
        domain.flags == (::Libvirt::Domain::AFFECT_CONFIG | ::Libvirt::Domain::AFFECT_LIVE)
    end

    returns(true, "returns ejection success when live cdrom detach is unsupported") do
      domain = DetachIsoFakeDomain.new(:active => true, :fail_detach => true)
      client = DetachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"

      ok = service.detach_iso(uuid)

      ok &&
        domain.calls == [:update] &&
        domain.update_xml.include?('tray="open"')
    end

    returns(true, "respects combined flags that already include AFFECT_CONFIG") do
      domain = DetachIsoFakeDomain.new(:active => true)
      client = DetachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      combined_flags = ::Libvirt::Domain::AFFECT_CONFIG | ::Libvirt::Domain::AFFECT_LIVE

      ok = service.detach_iso(uuid, :flags => combined_flags)

      ok &&
        domain.flags == combined_flags
    end
  end
end
