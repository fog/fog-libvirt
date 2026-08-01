require "fog/core/model"
require "nokogiri"
require_relative "../../../common/attribute_model"
require_relative "../../../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Source < AttributeModel
            class DataStore < AttributeModel
              include Fog::Libvirt::Util

              attribute :type
              attribute :format
              attribute :source

              autocast_on_assign :source, Source

              def initialize(attributes = {})
                super(normalize_attrs(attributes))
              end

              def self.parse_xml(node)
                return nil unless node

                attrs = xml_attrs(node)
                attrs[:type] = attrs[:type].to_sym if attrs[:type]
                attrs[:format] = node.at_xpath("format").to_h["type"]&.to_sym
                attrs[:source] = Source.parse_xml(node.at_xpath("source"))
                attrs.compact
              end

              def build_xml(xml)
                xml.dataStore(attrs_xml(attributes.except(:format, :source).compact)) do
                  xml.format(:type => format) if format
                  source&.build_xml(xml)
                end
              end

              private

              def normalize_attrs(attrs)
                attrs[:type] = attrs[:type].to_sym unless attrs[:type].to_s.empty?
                attrs[:type] = attrs.delete("type").to_sym unless attrs["type"].to_s.empty?
                attrs[:format] = attrs[:format].to_sym unless attrs[:format].to_s.empty?
                attrs[:format] = attrs.delete("format").to_sym unless attrs["format"].to_s.empty?
                attrs
              end
            end
          end
        end
      end
    end
  end
end
