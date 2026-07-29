require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DhcpLease < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :expiry, :type => Integer
          attribute :unit

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:expiry] = attrs[:expiry].to_i if attrs.key?(:expiry)
            attrs
          end

          def build_xml(xml)
            xml.lease(attributes.compact)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :expiry => attrs.to_i } if attrs.is_a?(Integer) || attrs.is_a?(String)
            attrs
          end
        end
      end
    end
  end
end
