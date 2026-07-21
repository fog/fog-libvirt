module Fog
  module Libvirt
    class Compute
      module Shared
        def create_network(xml)
          client.create_network_xml(xml)
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
