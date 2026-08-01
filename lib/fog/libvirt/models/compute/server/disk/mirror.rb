require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"
require_relative "format"
require_relative "source"
require_relative "backing_store"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Mirror < AttributeModel
            include Fog::Libvirt::Util

            attribute :type
            attribute :job
            attribute :ready

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
              attrs[:backing_store] = parse_xml(node.at_xpath("backingStore"))
              attrs.compact
            end
          end
        end
      end
    end
  end
end
