require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DnsForwarder < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :domain
          attribute :addr
          attribute :port

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:port] = attrs[:port].to_i if attrs.key?(:port)
            attrs
          end

          def build_xml(xml)
            xml.forwarder(attributes.compact)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :addr => attrs.to_s } unless attrs.is_a?(Hash)
            attrs[:port] = attrs[:port].to_i unless attrs[:port].to_s.empty?
            attrs[:port] = attrs.delete("port").to_i unless attrs["port"].to_s.empty?
            attrs
          end
        end
      end
    end
  end
end
