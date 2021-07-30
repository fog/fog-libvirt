module Fog
  module Libvirt
    class Compute
      class Real
        def vm_action(uuid, action, *params)
          domain = client.lookup_domain_by_uuid(uuid)
          domain.send(action, *params)
          true
        end
      end

      class Mock
        def vm_action(uuid, action, *params)
          true
        end
      end
    end
  end
end
