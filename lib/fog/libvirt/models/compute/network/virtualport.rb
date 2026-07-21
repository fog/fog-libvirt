require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Virtualport < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :type
          attribute :interfaceid
          attribute :profileid
          attribute :managerid
          attribute :typeid
          attribute :typeidversion
          attribute :instanceid

          def self.parse_xml(node)
            return nil unless node

            attrs = {}
            attrs[:type] = node["type"] if node["type"]
            attrs.merge!(xml_attrs(node.at_xpath("parameters")))

            attrs[:managerid] = attrs[:managerid].to_i if attrs.key?(:managerid)
            attrs[:typeid] = attrs[:typeid].to_i if attrs.key?(:typeid)
            attrs[:typeidversion] = attrs[:typeidversion].to_i if attrs.key?(:typeidversion)

            attrs
          end

          def build_xml(xml)
            attrs = attributes.slice(:type).compact
            parameters = hash_except(attributes, :type).compact
            xml.virtualport(attrs) do
              xml.parameters(parameters) unless parameters.empty?
            end
          end
        end
      end
    end
  end
end
