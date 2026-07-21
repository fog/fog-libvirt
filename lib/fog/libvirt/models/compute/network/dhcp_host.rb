require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "dhcp_lease"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DhcpHost < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :mac
          attribute :ip
          attribute :name
          attribute :id

          attribute :lease
          autocast_on_assign :lease, DhcpLease

          def ==(other)
            return super unless other.is_a?(DhcpHost)

            (!mac.nil? && mac == other.mac) ||
              (!ip.nil? && ip.to_s == other.ip.to_s) ||
              (!name.nil? && name == other.name)
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:lease] = DhcpLease.parse_xml(node.at_xpath("lease"))
            attrs.delete(:lease) unless attrs[:lease]
            attrs
          end

          def build_xml(xml)
            xml.host(hash_except(attributes, :lease).compact.transform_values(&:to_s)) do
              lease&.build_xml(xml)
            end
          end

          def section
            :dhcp_host
          end

          def self.save_fragment(new, old, parent_index, network)
            network.save_fragment(models_cast(new, self), old, :parent_index => parent_index)
          end
        end
      end
    end
  end
end
