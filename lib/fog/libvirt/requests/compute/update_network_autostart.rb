module Fog
  module Libvirt
    class Compute
      module Shared
        def update_network_autostart(uuid, value)
          network = client.lookup_network_by_uuid(uuid)
          previous = network.autostart
          network.autostart = value
          previous
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
