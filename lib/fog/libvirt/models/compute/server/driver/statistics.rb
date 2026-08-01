require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../util/util"
require_relative "latency_histogram"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        module Driver
          class Statistics < AttributeModel
            include Fog::Libvirt::Util

            attribute :intervals
            attribute :latency_histograms

            autocast_on_assign :latency_histograms, [LatencyHistogram]

            def self.parse_xml(node)
              return nil unless node

              attrs = {}
              attrs[:intervals] = node.xpath("statistic").map { |statistic_node| xml_attrs(statistic_node)[:interval].to_i }
              attrs.delete(:intervals) if attrs[:intervals].empty?

              attrs[:latency_histograms] = node.xpath("latency-histogram").map { |latency_histogram_node| LatencyHistogram.parse_xml(latency_histogram_node) }
              attrs.delete(:latency_histograms) if attrs[:latency_histograms].empty?

              attrs
            end

            def build_xml(xml)
              xml.statistics do
                intervals.each { |interval| xml.statistic(:interval => interval) }
                latency_histograms.each { |latency_histogram| model_cast(latency_histogram, LatencyHistogram).build_xml(xml) }
              end
            end
          end
        end
      end
    end
  end
end
