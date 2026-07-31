require "nokogiri"

module Fog
  module Libvirt
    class Compute
      module Shared
        include Fog::Libvirt::Util

        def attach_iso(uuid, iso_path, options = {})
          raise ArgumentError, "uuid is a required parameter" if uuid.nil?
          raise ArgumentError, "iso_path is a required parameter" if iso_path.nil?

          options ||= {}
          raise ArgumentError, "options must be a hash" unless options.is_a?(Hash)

          target_dev = options.fetch(:target_dev, DEFAULT_CDROM_TARGET_DEV)
          bus = options.fetch(:bus, DEFAULT_CDROM_BUS)
          flags = options.fetch(:flags, ::Libvirt::Domain::AFFECT_CONFIG)

          resolved_iso_path = File.absolute_path?(iso_path) ? iso_path : File.join(default_iso_dir, iso_path)
          xml = attach_cdrom_xml(resolved_iso_path, target_dev, bus)

          domain = client.lookup_domain_by_uuid(uuid)
          begin
            domain.attach_device(xml, flags)
          rescue ::Libvirt::Error => e
            begin
              domain.update_device(xml, flags)
            rescue ::Libvirt::Error
              raise e
            end
          end

          # if we get no exception, we assume the operation was successful
          true
        end

        private

        def attach_cdrom_xml(iso_path, target_dev, bus)
          Nokogiri::XML::Builder.new do |x|
            x.disk(:type => "file", :device => "cdrom") do
              x.driver(:name => "qemu", :type => "raw")
              x.source(:file => iso_path)
              x.target(:dev => target_dev, :bus => bus)
              x.readonly
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
