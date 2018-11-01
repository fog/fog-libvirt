module Fog
  module Libvirt
    class Compute
      class Real
        def define_domain(xml)
          client.define_domain_xml(xml)
        end
      end

      class Mock
        def define_domain(xml)
          ::Libvirt::Domain.new()
        end
      end
    end
  end
end
