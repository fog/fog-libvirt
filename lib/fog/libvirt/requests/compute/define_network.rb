module Fog
  module Libvirt
    class Compute
      module Shared
        def define_network(xml)
          client.define_network_xml(xml)
        end
      end

      class Real
        include Shared
      end

      class Mock
        include Shared
      end
    end
  end
end
