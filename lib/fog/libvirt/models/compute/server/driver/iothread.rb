require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        module Driver
          class IOThread < AttributeModel
            include Fog::Libvirt::Util

            attribute :id
            attribute :queues, :type => Array

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node)
              attrs[:id] = attrs[:id].to_i if attrs.key?(:id)
              attrs[:queues] = node.xpath("queue").map { |queue_node| xml_attrs(queue_node)[:id].to_i }
              attrs.delete(:queues) if attrs[:queues].empty?
              attrs
            end

            def build_xml(xml)
              xml.iothread(attrs_xml(attributes.except(:queues).compact)) do
                queues.each { |queue| xml.queue(:id => queue) }
              end
            end
          end
        end
      end
    end
  end
end
