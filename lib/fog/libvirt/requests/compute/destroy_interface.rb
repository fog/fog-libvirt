module Fog
  module Libvirt
    class Compute
      class Real
        #shutdown the interface
        def destroy_interface(uuid)
          client.lookup_interface_by_uuid(uuid).destroy
        end
      end

      class Mock
        def destroy_interface(uuid)
          true
        end
      end
    end
  end
end
