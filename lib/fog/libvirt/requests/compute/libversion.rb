
module Fog
  module Libvirt
    class Compute
      class Real
        def libversion()
          client.libversion
        end
      end

      class Mock
        def libversion()
          return 1002009
        end
      end
    end
  end
end
