module Fog
  module Libvirt
    class Compute
      class Real
        def create_domain(xml)
          client.create_domain_xml(xml)
        end
      end

      class Mock
        def create_domain(xml)
          ::Libvirt::Domain.new()
        end
      end
    end
  end
end
