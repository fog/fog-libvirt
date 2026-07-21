require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Route < Fog::Model
          include Fog::Libvirt::Util

          identity :gateway
          attribute :address
          attribute :netmask
          attribute :prefix
          attribute :family
          attribute :metric

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:prefix] = attrs[:prefix].to_i if attrs.key?(:prefix)
            attrs[:metric] = attrs[:metric].to_i if attrs.key?(:metric)
            attrs
          end

          def build_xml(xml)
            xml.route(attributes.compact.transform_values(&:to_s))
          end

          private

          def normalize_attrs(attrs)
            attrs = { :gateway => attrs } if attrs.is_a?(String)
            attrs[:prefix] = attrs[:prefix].to_i unless attrs[:prefix].to_s.empty?
            attrs[:prefix] = attrs.delete("prefix").to_i unless attrs["prefix"].to_s.empty?
            attrs[:metric] = attrs[:metric].to_i unless attrs[:metric].to_s.empty?
            attrs[:metric] = attrs.delete("metric").to_i unless attrs["metric"].to_s.empty?
            attrs
          end
        end
      end
    end
  end
end
