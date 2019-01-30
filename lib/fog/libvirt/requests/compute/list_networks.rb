module Fog
  module Libvirt
    class Compute
      class Real
        def list_networks(filter = { })
          data=[]
          if filter.keys.empty?
            (client.list_networks + client.list_defined_networks).each do |network_name|
              data << network_to_attributes(client.lookup_network_by_name(network_name))
            end
          else
            data = [network_to_attributes(get_network_by_filter(filter))]
          end
          data
        end

        private
        # Retrieve the network by uuid or name
        def get_network_by_filter(filter)
          case filter.keys.first
            when :uuid
              client.lookup_network_by_uuid(filter[:uuid])
            when :name
              client.lookup_network_by_name(filter[:name])
          end
        end

        def network_to_attributes(net)
          return if net.nil?
          {
            :uuid        => net.uuid,
            :name        => net.name,
            :bridge_name => net.bridge_name
          }
        end
      end

      class Mock
        def list_networks(filters={ })
          [ {
              :uuid        => 'a29146ea-39b2-412d-8f53-239eef117a32',
              :name        => 'net1',
              :bridge_name => 'virbr0'
            },
            {
              :uuid        => 'fbd4ac68-cbea-4f95-86ed-22953fd92384',
              :name        => 'net2',
              :bridge_name => 'virbr1'
            }
          ]
        end
      end
    end
  end
end
