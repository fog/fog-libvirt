require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "dhcp_lease"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DhcpRange < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :start
          attribute :end

          attribute :lease
          autocast_on_assign :lease, DhcpLease

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def ==(other)
            return super unless other.is_a?(DhcpRange)

            start.to_s == other.start.to_s &&
              self.end.to_s == other.end.to_s
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:lease] = DhcpLease.parse_xml(node.at_xpath("lease"))
            attrs.delete(:lease) unless attrs[:lease]
            attrs
          end

          def build_xml(xml)
            xml.range(hash_except(attributes, :lease).compact.transform_values(&:to_s)) do
              lease&.build_xml(xml)
            end
          end

          def update_modify?(_service)
            # Libvirt doesn't support MODIFY for IP_DHCP_RANGE
            false
          end

          def section
            :dhcp_range
          end

          def self.save_fragment(new, old, parent_index, network)
            network.save_fragment(models_cast(new, self), old, :parent_index => parent_index)
          end

          private

          def normalize_attrs(attrs)
            attrs = normalize_ip_range(attrs) if attrs.is_a?(Range)
            attrs
          end
        end
      end
    end
  end
end
