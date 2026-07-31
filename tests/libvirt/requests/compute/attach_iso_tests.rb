require File.expand_path("../../../helper", __dir__)
require "fog/libvirt"

class AttachIsoFakeDomain
  attr_reader :xml, :flags, :calls, :xml_desc

  def initialize(xml_desc, fail_attach: false, fail_update: false)
    @xml_desc = xml_desc
    @calls = []
    @fail_attach = fail_attach
    @fail_update = fail_update
  end

  def update_device(xml, flags = 0)
    raise ::Libvirt::Error, "update failed" if @fail_update

    @calls << :update
    @xml = xml
    @flags = flags
    true
  end

  def attach_device(xml, flags = 0)
    raise ::Libvirt::Error, "attach failed" if @fail_attach

    @calls << :attach
    @xml = xml
    @flags = flags
    true
  end
end

class AttachIsoFakeClient
  def initialize(domain)
    @domain = domain
  end

  def lookup_domain_by_uuid(_uuid)
    @domain
  end
end

Shindo.tests("Fog::Compute[:libvirt] | attach_iso") do
  tests("attach_iso") do
    returns(true, "attaches cdrom device directly when attach succeeds") do
      domain = AttachIsoFakeDomain.new("<domain><devices></devices></domain>")
      client = AttachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      iso = "/var/lib/libvirt/images/os.iso"

      ok = service.attach_iso(uuid, iso, :target_dev => "sdc", :bus => "sata", :flags => 0)

      ok &&
        domain.calls == [:attach] &&
        domain.xml.include?('device="cdrom"') &&
        domain.xml.include?('type="file"') &&
        domain.xml.include?("<source") &&
        domain.xml.include?(iso) &&
        domain.xml.include?('dev="sdc"') &&
        domain.xml.include?('bus="sata"') &&
        domain.xml.include?("readonly")
    end

    returns(true, "falls back to update when attach fails") do
      domain = AttachIsoFakeDomain.new(
        '<domain><devices><disk device="cdrom"><target dev="sdc" bus="sata"/></disk></devices></domain>',
        :fail_attach => true
      )
      client = AttachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      iso = "/var/lib/libvirt/images/os.iso"

      ok = service.attach_iso(uuid, iso, :target_dev => "sdc", :bus => "sata", :flags => 0)

      ok &&
        domain.calls == [:update] &&
        domain.xml.include?('device="cdrom"') &&
        domain.xml.include?('type="file"') &&
        domain.xml.include?("<source") &&
        domain.xml.include?(iso) &&
        domain.xml.include?('dev="sdc"') &&
        domain.xml.include?('bus="sata"') &&
        domain.xml.include?("readonly")
    end

    returns(true, "resolves relative iso path using default_iso_dir") do
      domain = AttachIsoFakeDomain.new("<domain><devices></devices></domain>")
      client = AttachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      iso = "os.iso"

      ok = service.attach_iso(uuid, iso)

      ok &&
        domain.calls == [:attach] &&
        domain.xml.include?('file="/var/lib/libvirt/images/os.iso"')
    end

    raises(::Libvirt::Error, "raises when both attach and update fail") do
      domain = AttachIsoFakeDomain.new(
        "<domain><devices></devices></domain>",
        :fail_attach => true,
        :fail_update => true
      )
      client = AttachIsoFakeClient.new(domain)

      service = Fog::Libvirt::Compute::Real.allocate
      service.instance_variable_set(:@client, client)

      uuid = "11111111-2222-3333-4444-555555555555"
      iso = "/var/lib/libvirt/images/os.iso"

      service.attach_iso(uuid, iso, :target_dev => "sdc", :bus => "sata", :flags => 0)
    end
  end
end
