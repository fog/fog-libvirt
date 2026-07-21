require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Domain < Fog::Model
          include Fog::Libvirt::Util

          identity :name
          attribute :local_only
          attribute :register

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            xml_attrs(node)
          end

          def build_xml(xml)
            xml.domain(attrs_xml(attributes).compact)
          end

          def normalize_attrs(attrs)
            attrs = { :name => attrs } if attrs.is_a?(String)
            attrs_underscore(attrs)
          end
        end
      end
    end
  end
end
