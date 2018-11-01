module Fog
  module Libvirt
    class Compute
      class Real
        def vm_action(uuid, action)
          domain = client.lookup_domain_by_uuid(uuid)
          domain.send(action)
          true
        end
      end

      class Mock
        def vm_action(uuid, action)
          true
        end
      end
    end
  end
end
