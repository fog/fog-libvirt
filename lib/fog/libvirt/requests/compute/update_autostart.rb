module Fog
  module Libvirt
    class Compute
      class Real
        def update_autostart(uuid, value)
          domain = client.lookup_domain_by_uuid(uuid)
          domain.autostart = value
        end
      end

      class Mock
        def update_autostart(uuid, value)
          value
        end
      end
    end
  end
end
