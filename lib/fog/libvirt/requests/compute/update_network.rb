module Fog
  module Libvirt
    class Compute
      module Shared
        def update_network(network, xml, persistent, active, autostart)
          currently_persistent = network&.persistent?
          network.destroy if network&.active?
          network.undefine if currently_persistent

          if persistent || persistent.nil?
            new_network = define_network(xml)
            new_network.create if active
            new_network.autostart = true if autostart
          else
            new_network = create_network(xml)
          end

          new_network
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
