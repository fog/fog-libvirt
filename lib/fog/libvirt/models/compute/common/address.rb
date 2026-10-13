require "fog/core/model"
require_relative "attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Address < Fog::Libvirt::Compute::AttributeModel
        include Fog::Libvirt::Util

        attribute :type

        def self.new(attributes = {})
          return super if self != Address

          klass = types[attributes[:type]&.to_sym]
          klass ? klass.new(attributes) : super
        end

        def self.types
          require_relative "pci_address"
          require_relative "drive_address"
          {
            :pci => PciAddress,
            :drive => DriveAddress
          }
        end

        def self.parse_xml(node)
          return nil unless node

          xml_attrs(node)
        end

        def build_xml(xml)
          xml.address(attrs_xml(attributes.compact, :switch => true))
        end
      end
    end
  end
end
