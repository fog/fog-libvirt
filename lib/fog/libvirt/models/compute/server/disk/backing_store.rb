require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"
require_relative "format"
require_relative "source"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class BackingStore < AttributeModel
            include Fog::Libvirt::Util

            attribute :type

            attribute :format
            attribute :source
            attribute :backing_store

            autocast_on_assign :format, Format
            autocast_on_assign :source, Source
            autocast_on_assign :backing_store, BackingStore

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node)
              attrs[:format] = Format.parse_xml(node.at_xpath("format"))
              attrs[:source] = Source.parse_xml(node.at_xpath("source"))
              attrs[:backing_store] = BackingStore.parse_xml(node.at_xpath("backingStore"))
              attrs.compact
            end

            # read-only
            def index
              attributes[:index]
            end

            def build_xml(xml)
              xml.backingStore(attrs_xml(attributes.except(:index, :format, :source, :backing_store).compact)) do
                format&.build_xml(xml)
                source&.build_xml(xml)
                backing_store&.build_xml(xml)
              end
            end
          end
        end
      end
    end
  end
end
