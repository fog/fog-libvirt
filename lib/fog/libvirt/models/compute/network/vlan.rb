require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "vlan_tag"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Vlan < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :trunk
          attribute :tags, :type => Array

          autocast_on_assign :tags, [VlanTag]

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:tags] = node.xpath("tag").map { |tag_node| VlanTag.parse_xml(tag_node) }
            attrs.delete(:tags) if attrs[:tags].empty?
            attrs
          end

          def build_xml(xml)
            xml.vlan(attrs_xml(hash_except(attributes, :tags)).compact) do
              tags.each { |tag| model_cast(tag, VlanTag).build_xml(xml) }
            end
          end
        end
      end
    end
  end
end
