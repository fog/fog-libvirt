require "nokogiri"

module Fog
  module Libvirt
    class Compute
      module Shared
        def upload_iso(pool_name, volume_name, file_path)
          raise ArgumentError, "pool_name is a required parameter" if pool_name.nil?
          raise ArgumentError, "volume_name is a required parameter" if volume_name.nil?
          raise ArgumentError, "file_path is a required parameter" if file_path.nil?

          pool = client.lookup_storage_pool_by_name(pool_name)
          pool.lookup_volume_by_name(volume_name).delete if pool.list_volumes.include?(volume_name)

          create_volume(pool_name, iso_volume_xml(volume_name, file_path))
          upload_volume(pool_name, volume_name, file_path)

          volume = pool.lookup_volume_by_name(volume_name)
          {
            :pool_name => pool_name,
            :name => volume_name,
            :key => volume.key,
            :path => volume.path
          }
        end

        private

        def iso_volume_xml(volume_name, file_path)
          iso_size = File.size(file_path)

          Nokogiri::XML::Builder.new do |x|
            x.volume do
              x.name(volume_name)
              x.allocation(0, :unit => "B")
              x.capacity(iso_size, :unit => "B")
              x.target do
                x.format(:type => "raw")
              end
            end
          end.to_xml
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
