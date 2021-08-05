module Fog
  module Libvirt
    class Compute
      class Real
        def list_domains(filter = { })
          data=[]

          if filter.key?(:uuid)
            data << client.lookup_domain_by_uuid(filter[:uuid])
          elsif filter.key?(:name)
            data << client.lookup_domain_by_name(filter[:name])
          else
            client.list_defined_domains.each { |name| data << catchLibvirtExceptions { client.lookup_domain_by_name(name) } } unless filter[:defined] == false
            client.list_domains.each { |id| data << catchLibvirtExceptions { client.lookup_domain_by_id(id) } } unless filter[:active] == false
          end
          data.compact.map { |d| domain_to_attributes d }.compact
        end

        # Catch Libvirt exceptions to avoid race conditions involving
        # concurrent libvirt operations from other processes. For example,
        # domains being undefined while fog-libvirt is trying to work with
        # domain lists.
        def catchLibvirtExceptions
          yield
        rescue ::Libvirt::RetrieveError, ::Libvirt::Error
          nil
        end
      end

      module Shared
        private

        def domain_display xml
          attrs = {}
          [:type, :port, :password, :listen].each do |element|
            attrs[element] = xml_element(xml, "domain/devices/graphics",element.to_s) rescue nil
          end
          attrs.reject{|k,v| v.nil? or v == ""}
        end

        def domain_volumes xml
          vols_by_file = xml_elements(xml, "domain/devices/disk/source", "file")
          vols_by_name = xml_elements(xml, "domain/devices/disk/source", "name")
          vols = []
          vols_by_file.zip(vols_by_name).each do |by_file,by_name|
            vols.push(by_file.nil? ? by_name : by_file)
          end
          vols
        end

        def boot_order xml
          xml_elements(xml, "domain/os/boot", "dev")
        end

        def domain_interfaces xml
          ifs = xml_elements(xml, "domain/devices/interface")
          ifs.map { |i|
            nics.new({
              :type    => i['type'],
              :mac     => (i/'mac').first[:address],
              :network => ((i/'source').first[:network] rescue nil),
              :bridge  => ((i/'source').first[:bridge] rescue nil),
              :model   => ((i/'model').first[:type] rescue nil),
            }.reject{|k,v| v.nil?})
          }
        end

        def domain_to_attributes(dom)
          states= %w(nostate running blocked paused shutting-down shutoff crashed pmsuspended)

          begin
            {
              :id              => dom.uuid,
              :uuid            => dom.uuid,
              :name            => dom.name,
              :max_memory_size => dom.info.max_mem,
              :cputime         => dom.info.cpu_time,
              :memory_size     => dom.info.memory,
              :cpus            => dom.info.nr_virt_cpu,
              :autostart       => dom.autostart?,
              :os_type         => dom.os_type,
              :active          => dom.active?,
              :display         => domain_display(dom.xml_desc),
              :boot_order      => boot_order(dom.xml_desc),
              :nics            => domain_interfaces(dom.xml_desc),
              :volumes_path    => domain_volumes(dom.xml_desc),
              :state           => states[dom.info.state]
            }
          rescue ::Libvirt::RetrieveError, ::Libvirt::Error
            # Catch libvirt exceptions to avoid race conditions involving
            # concurrent libvirt operations (like from another process)
            return nil
          end
        end
      end

      class Mock
        def list_domains(filter = { })
          dom1 = mock_domain 'fog-dom1'
          dom2 = mock_domain 'fog-dom2'
          dom3 = mock_domain 'a-fog-dom3'
          [dom1, dom2, dom3]
        end

        def mock_domain name
          xml = read_xml 'domain.xml'
          {
              :id              => "dom.uuid",
              :uuid            => "dom.uuid",
              :name            => name,
              :max_memory_size => 8,
              :cputime         => 7,
              :memory_size     => 6,
              :cpus            => 5,
              :autostart       => false,
              :os_type         => "RHEL6",
              :active          => false,
              :vnc_port        => 5910,
              :boot_order      => boot_order(xml),
              :nics            => domain_interfaces(xml),
              :volumes_path    => domain_volumes(xml),
              :state           => 'shutoff'
          }
        end
      end
    end
  end
end
