require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        module Driver
          class LatencyHistogram < AttributeModel
            include Fog::Libvirt::Util

            attribute :type
            attribute :bins, :type => Array

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node)
              attrs[:bins] = node.xpath("bin").map { |bin_node| xml_attrs(bin_node)[:start].to_i }
              attrs.delete(:bins) if attrs[:bins].empty?
              attrs
            end

            def build_xml(xml)
              xml.public_send("latency-histogram", attrs_xml(attributes.except(:bins).compact)) do
                bins.each { |bin| xml.bin(:start => bin) }
              end
            end
          end
        end
      end
    end
  end
end
