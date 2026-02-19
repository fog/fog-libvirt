require "nokogiri"

module Fog
  module Libvirt
    class Compute
      module Shared
        include Fog::Libvirt::Util

        def detach_iso(uuid, options = {})
          raise ArgumentError, "uuid is a required parameter" if uuid.nil?

          options ||= {}
          raise ArgumentError, "options must be a hash" unless options.is_a?(Hash)

          target_dev = options.fetch(:target_dev, DEFAULT_CDROM_TARGET_DEV)
          bus = options.fetch(:bus, DEFAULT_CDROM_BUS)
          flags = options.fetch(:flags, ::Libvirt::Domain::AFFECT_CONFIG)
          domain = client.lookup_domain_by_uuid(uuid)
          domain_active = domain.active?
          flags = effective_detach_iso_flags(flags, domain_active)

          if domain_active
            domain.update_device(eject_cdrom_xml(target_dev, bus), flags)
            begin
              domain.detach_device(detach_cdrom_xml(target_dev, bus), flags)
            rescue ::Libvirt::Error
              # Some backends don't allow to detach the cdrom if the host is running.
              # In this case, we just eject the cdrom and leave it attached to the VM.
              # Return true that maybe the ISO file can be removed in further steps.
              true
            end
          else
            begin
              domain.detach_device(detach_cdrom_xml(target_dev, bus), flags)
              true
            rescue ::Libvirt::Error
              false
            end
          end
        end

        private

        def detach_cdrom_xml(target_dev, bus)
          Nokogiri::XML::Builder.new do |x|
            x.disk(:type => "file", :device => "cdrom") do
              x.target(:dev => target_dev, :bus => bus)
            end
          end.to_xml
        end

        def eject_cdrom_xml(target_dev, bus)
          Nokogiri::XML::Builder.new do |x|
            x.disk(:type => "file", :device => "cdrom", :tray => "open") do
              x.driver(:name => "qemu", :type => "raw")
              x.target(:dev => target_dev, :bus => bus)
              x.readonly
            end
          end.to_xml
        end

        def effective_detach_iso_flags(flags, domain_active)
          return flags unless (flags & ::Libvirt::Domain::AFFECT_CONFIG) == ::Libvirt::Domain::AFFECT_CONFIG
          return flags unless domain_active

          flags | ::Libvirt::Domain::AFFECT_LIVE
        rescue ::Libvirt::Error
          flags
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
