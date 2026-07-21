require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class VlanTag < Fog::Model
          include Fog::Libvirt::Util

          identity :id, :type => Integer

          attribute :native_mode

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            xml_attrs(node)
          end

          def build_xml(xml)
            xml.tag(attrs_xml(attributes).compact)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :id => attrs } if attrs.is_a?(Integer) || attrs.is_a?(String)
            attrs_underscore(attrs)
          end
        end
      end
    end
  end
end
