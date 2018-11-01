module Fog
  module Libvirt
    class Compute
      class Real
        def destroy_network(uuid)
          client.lookup_network_by_uuid(uuid).destroy
        end
      end

      class Mock
        def destroy_network(uuid)
          true
        end
      end
    end
  end
end
