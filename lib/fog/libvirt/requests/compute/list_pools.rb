module Fog
  module Libvirt
    class Compute
      class Real
        def list_pools(filter = { })
          data=[]
          if filter.key?(:name)
            data << find_pool_by_name(filter[:name], filter[:include_inactive])
          elsif filter.key?(:uuid)
            data << find_pool_by_uuid(filter[:uuid], filter[:include_inactive])
          else
            (client.list_storage_pools + client.list_defined_storage_pools).each do |name|
              data << find_pool_by_name(name, filter[:include_inactive])
            end
          end
          data.compact
        end

        private

        private_class_method def self.pool_to_attributes(pool, include_inactive = nil)
          return nil unless pool.active? || include_inactive

          states=[:inactive, :building, :running, :degrated, :inaccessible]
          {
            :uuid           => pool.uuid,
            :persistent     => pool.persistent?,
            :autostart      => pool.autostart?,
            :active         => pool.active?,
            :name           => pool.name,
            :allocation     => pool.info.allocation,
            :capacity       => pool.info.capacity,
            :num_of_volumes => pool.active? ? pool.num_of_volumes : nil,
            :state          => states[pool.info.state]
          }
        end

        def find_pool_by_name name, include_inactive
          pool_to_attributes(client.lookup_storage_pool_by_name(name), include_inactive)
        rescue ::Libvirt::RetrieveError
          nil
        end

        def find_pool_by_uuid uuid, include_inactive
          pool_to_attributes(client.lookup_storage_pool_by_uuid(uuid), include_inactive)
        rescue ::Libvirt::RetrieveError
          nil
        end
      end

      class Mock
        def list_pools(filter = { })
          pool1 = mock_pool 'pool1'
          pool2 = mock_pool 'pool1'
          [pool1, pool2]
        end

        def mock_pool name
          {
              :uuid           => 'pool.uuid',
              :persistent     => true,
              :autostart      => true,
              :active         => true,
              :name           => name,
              :allocation     => 123456789,
              :capacity       => 123456789,
              :num_of_volumes => 3,
              :state          => :running
          }
        end
      end
    end
  end
end
