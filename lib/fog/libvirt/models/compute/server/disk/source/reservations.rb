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
            class Reservations < AttributeModel
              include Fog::Libvirt::Util

              attribute :managed
              attribute :migration

              attribute :source

              def self.parse_xml(node)
                return nil unless node

                attrs = xml_attrs(node)
                attrs[:source] = xml_attrs(node.at_xpath("source"))
                attrs.delete(:source) if attrs[:source].empty?

                attrs
              end

              def build_xml(xml)
                xml.reservations(attrs_xml(attributes.except(:source).compact)) do
                  xml.source(attrs_xml(source.compact)) if source
                end
              end
            end
          end
        end
      end
    end
  end
end
