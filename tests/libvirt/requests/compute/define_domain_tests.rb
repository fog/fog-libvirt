Shindo.tests("Fog::Compute[:libvirt] | define_domain request", 'libvirt') do

  compute = Fog::Compute[:libvirt]
  server = compute.servers.new(:name => "fog-test-define-server", :nics => [])
  xml = server.to_xml

  tests("Define Domain") do
    response = compute.define_domain(xml)
    test("should be a kind of Libvirt::Domain") { response.kind_of?  Libvirt::Domain}
  end
ensure
  server_uuid = compute.servers.all(:name => server.name).first&.uuid
  compute.servers.service.vm_action(server_uuid, :undefine) if server_uuid
end
