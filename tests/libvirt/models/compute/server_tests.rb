Shindo.tests('Fog::Compute[:libvirt] | server model', ['libvirt']) do

  servers = Fog::Compute[:libvirt].servers
  server = servers.all.select{|v| v.name =~ /^fog/}.last

  tests('The server model should') do
    tests('have the action') do
      test('reload') { server.respond_to? 'reload' }
      %w{ start stop destroy reboot suspend }.each do |action|
        test(action) { server.respond_to? action }
      end
      %w{ start reboot suspend stop destroy}.each do |action|
        test("#{action} returns successfully") {
          begin
            server.send(action.to_sym)
          rescue Libvirt::Error
            #libvirt error is acceptable for the above actions.
            true
          end
        }
      end
    end
    tests('have an ip_address action that') do
      test('returns the latest IP address lease') { server.public_ip_address() == '1.2.5.6' }
    end
    tests('have attributes') do
      model_attribute_hash = server.attributes
      attributes = [ :id,
        :cpus,
        :cputime,
        :os_type,
        :memory_size,
        :max_memory_size,
        :name,
        :arch,
        :persistent,
        :domain_type,
        :uuid,
        :autostart,
        :display,
        :nics,
        :volumes,
        :active,
        :boot_order,
        :state]
      tests("The server model should respond to") do
        attributes.each do |attribute|
          test("#{attribute}") { server.respond_to? attribute }
        end
      end
      tests("The attributes hash should have key") do
        attributes.delete(:volumes)
        attributes.each do |attribute|
          test("#{attribute}") { model_attribute_hash.key? attribute }
        end
      end
    end
    test('be a kind of Fog::Libvirt::Compute::Server') { server.kind_of? Fog::Libvirt::Compute::Server }
  end
end
