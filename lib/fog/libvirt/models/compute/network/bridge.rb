require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Bridge < Fog::Model
          include Fog::Libvirt::Util

          identity :name
          attribute :zone
          attribute :stp
          attribute :delay, :type => Integer
          attribute :mac_table_manager

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:delay] = attrs[:delay].to_i if attrs.key?(:delay)
            attrs
          end

          def build_xml(xml)
            attrs = attrs_xml(attributes)
            attrs[:stp] = xml_switch(stp) # libvirt uses on/off for this rather than yes/no
            xml.bridge(attrs.compact)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :name => attrs } if attrs.is_a?(String)
            attrs_underscore(attrs)
          end
        end
      end
    end
  end
end
