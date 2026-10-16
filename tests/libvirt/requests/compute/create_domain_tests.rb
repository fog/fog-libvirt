Shindo.tests("Fog::Compute[:libvirt] | create_domain request", 'libvirt') do

  compute = Fog::Compute[:libvirt]

  server = compute.servers.new(:name => "fog-test-create-server", :nics => [])
  xml = server.to_xml

  tests("Create Domain") do
    response = compute.create_domain(xml)
    test("should be a kind of Libvirt::Domain") { response.kind_of?  Libvirt::Domain}
  end

  tests("Fail Creating Domain") do
    begin
      response = compute.create_domain(xml)
      test("should be a kind of Libvirt::Domain") { response.kind_of?  Libvirt::Domain} #mock never raise exceptions
    rescue => e
      #should raise vm name already exist exception.
      test("error should be a kind of Libvirt::Error") { e.kind_of?  Libvirt::Error}
    end
  end
ensure
  server_uuid = compute.servers.all(:name => server.name).first&.uuid
  compute.servers.service.vm_action(server_uuid, :destroy) if server_uuid
end
