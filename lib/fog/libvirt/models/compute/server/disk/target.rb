require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Target < AttributeModel
            include Fog::Libvirt::Util

            attribute :dev
            attribute :bus
            attribute :tray
            attribute :rotation_rate
            attribute :dpofua

            def self.parse_xml(node)
              return nil unless node

              xml_attrs(node, :autocast_int => true)
            end

            def build_xml(xml)
              xml.target(attrs_xml(attributes, :casing => :snake, :switch => true))
            end
          end
        end
      end
    end
  end
end
