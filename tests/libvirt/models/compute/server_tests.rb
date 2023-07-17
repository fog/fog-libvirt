Shindo.tests('Fog::Compute[:libvirt] | server model', ['libvirt']) do

  servers = Fog::Compute[:libvirt].servers
  server = servers.all.select{|v| v.name =~ /^fog/}.last

  tests('The server model should') do
    tests('have the action') do
      test('autostart') { server.respond_to? 'autostart' }
      test('update_autostart') { server.respond_to? 'update_autostart' }
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
        :hugepages,
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
    tests("serializes to xml") do
      test("with memory") { server.to_xml.match?(%r{<memory>\d+</memory>}) }
      test("with disk of type file") do
        xml = server.to_xml
        xml.match?(/<disk type="file" device="disk">/) && xml.match?(%r{<source file="path/to/disk"/>})
      end
      test("with disk of type block") do
        server = Fog::Libvirt::Compute::Server.new(
          {
            :nics => [],
            :volumes => [
              Fog::Libvirt::Compute::Volume.new({ :path => "/dev/sda", :pool_name => "dummy" })
            ]
          }
        )
        xml = server.to_xml
        xml.match?(/<disk type="block" device="disk">/) && xml.match?(%r{<source dev="/dev/sda"/>})
      end
    end
  end
end
