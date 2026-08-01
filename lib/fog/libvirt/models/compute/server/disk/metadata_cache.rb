require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class MetadataCache < AttributeModel
            include Fog::Libvirt::Util

            attribute :max_size

            def initialize(attributes = {})
              super(normalize_attrs(attributes))
            end

            def self.parse_xml(node)
              return nil unless node

              attrs = {}
              attrs[:max_size] = parse_integer(node.at_xpath("max_size"))
              attrs.compact
            end

            def self.parse_integer(node)
              return nil unless node

              attrs = xml_attrs(node)
              attrs[:value] = node.content.to_i
              attrs
            end

            def build_xml(xml)
              xml.metadata_cache do
                xml.max_size(attrs_xml(max_size.except(:value).compact), max_size[:value]) if max_size
              end
            end

            private

            def normalize_attrs(attrs)
              attrs = { :max_size => attrs } unless attrs.is_a?(Hash)
              attrs.transform_keys!(&:to_sym)
              attrs[:max_size] = { :value => attrs[:max_size].to_i, :unit => "bytes" } if attrs.key?(:max_size) && !attrs[:max_size].is_a?(Hash)
              attrs
            end
          end
        end
      end
    end
  end
end
