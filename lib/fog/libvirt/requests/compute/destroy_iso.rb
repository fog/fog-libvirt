module Fog
  module Libvirt
    class Compute
      module Shared
        def destroy_iso(pool_name, volume_name)
          raise ArgumentError, "pool_name is a required parameter" if pool_name.nil?
          raise ArgumentError, "volume_name is a required parameter" if volume_name.nil?

          pool = client.lookup_storage_pool_by_name(pool_name)
          begin
            pool.lookup_volume_by_name(volume_name).delete
          rescue ::Libvirt::RetrieveError
            # already absent, treat as success if not present afterwards
          end

          # if the ISO is absent, then we are good
          volume_absent?(pool, volume_name)
        end

        private

        def volume_absent?(pool, volume_name)
          pool.lookup_volume_by_name(volume_name)
          false
        rescue ::Libvirt::RetrieveError
          true
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
