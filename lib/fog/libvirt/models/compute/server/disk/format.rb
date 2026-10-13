require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"
require_relative "metadata_cache"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Format < AttributeModel
            include Fog::Libvirt::Util

            attribute :type

            attribute :metadata_cache

            autocast_on_assign :metadata_cache, MetadataCache

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node)
              attrs[:metadata_cache] = MetadataCache.parse_xml(node.at_xpath("metadata_cache"))
              attrs.compact
            end

            def build_xml(xml)
              xml.format(attrs_xml(attributes.except(:metadata_cache).compact)) do
                metadata_cache&.build_xml(xml)
              end
            end
          end
        end
      end
    end
  end
end
