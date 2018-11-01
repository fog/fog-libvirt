require 'socket'

module Fog
  module Libvirt
    class Compute
      class Real
        def dhcp_leases(uuid, mac, flags = 0)
          client.lookup_network_by_uuid(uuid).dhcp_leases(mac, flags)
        end
      end

      class Mock
        def dhcp_leases(uuid, mac, flags = 0)
          leases1 = {
            'aa:bb:cc:dd:ee:ff' => [
              { 'type' => Socket::AF_INET, 'ipaddr' => '1.2.3.4', 'prefix' => 24, 'expirytime' => 5000 },
              { 'type' => Socket::AF_INET, 'ipaddr' => '1.2.5.6', 'prefix' => 24, 'expirytime' => 5005 }
            ]
          }
          leases2 = {
            '99:88:77:66:55:44' => [
              { 'type' => Socket::AF_INET, 'ipaddr' => '10.1.1.5', 'prefix' => 24, 'expirytime' => 50 }
            ]
          }
          networks = {
            # should match mock net uuid from list_networks.rb
            'a29146ea-39b2-412d-8f53-239eef117a32' => leases1,
            'fbd4ac68-cbea-4f95-86ed-22953fd92384' => leases2
          }
          if !networks[uuid].nil?
            return networks[uuid][mac]
          end
        end
      end
    end
  end
end
