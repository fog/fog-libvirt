require "fog/core/model"
require "nokogiri"
require_relative "../common/attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Seclabel < AttributeModel
          include Fog::Libvirt::Util

          attribute :type
          attribute :model
          attribute :relabel

          attribute :label
          attribute :baselabel

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:type] = attrs[:type].to_sym if attrs[:type]
            attrs[:model] = attrs[:model].to_sym if attrs[:model]

            attrs[:label] = node.at_xpath("label")&.content
            attrs[:baselabel] = node.at_xpath("baselabel")&.content

            attrs[:imagelabel] = node.at_xpath("imagelabel")&.content

            attrs.compact
          end

          def build_xml(xml)
            xml.seclabel(attrs_xml(attributes.except(:label, :baselabel, :imagelabel, :labelskip).compact)) do
              xml.label(label) if label
              xml.baselabel(baselabel) if baselabel
            end
          end

          # read-only
          def imagelabel
            attributes[:imagelabel]
          end

          def labelskip?
            !!attributes[:labelskip]
          end

          private

          def normalize_attrs(attrs)
            attrs[:type] = attrs[:type].to_sym unless attrs[:type].to_s.empty?
            attrs[:type] = attrs.delete("type").to_sym unless attrs["type"].to_s.empty?
            attrs[:model] = attrs[:model].to_sym unless attrs[:model].to_s.empty?
            attrs[:model] = attrs.delete("model").to_sym unless attrs["model"].to_s.empty?
            attrs
          end
        end
      end
    end
  end
end
