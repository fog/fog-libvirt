require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class PciAddress < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :type
          attribute :domain
          attribute :bus
          attribute :slot
          attribute :function

          def initialize(attributes = {})
            super(defaults.merge(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            xml_attrs(node)
          end

          def build_xml(xml)
            xml.address(attributes.compact)
          end

          private

          def defaults
            { :type => "pci", :domain => 0 }
          end
        end
      end
    end
  end
end
