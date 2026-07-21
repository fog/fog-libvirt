require "fog/core/model"
require_relative "../attribute_model"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Dnsmasq < Fog::Libvirt::Compute::AttributeModel
          NAMESPACE = "http://libvirt.org/schemas/network/dnsmasq/1.0".freeze

          attribute :options, :type => Array

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            options = node.xpath("dnsmasq:option", "dnsmasq" => NAMESPACE).map { |option_node| option_node["value"] }
            { :options => options }
          end

          def build_xml(xml)
            return if options.empty?

            xml.doc.root.add_namespace("dnsmasq", NAMESPACE)

            xml["dnsmasq"].options do
              options.each do |option|
                xml["dnsmasq"].option({ :value => option })
              end
            end
          end

          private

          def normalize_attrs(attrs)
            if attrs.is_a?(String)
              attrs = { :options => [attrs] }
            elsif attrs.is_a?(Array)
              attrs = { :options => attrs }
            end
            attrs
          end
        end
      end
    end
  end
end
