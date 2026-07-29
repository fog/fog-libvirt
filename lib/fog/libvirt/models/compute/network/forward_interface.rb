require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class ForwardInterface < Fog::Model
          include Fog::Libvirt::Util

          identity :dev

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            xml_attrs(node)
          end

          def build_xml(xml)
            xml.interface(hash_except(attributes, :connections).compact)
          end

          def section
            :forward_interface
          end

          def update_modify?(_service)
            # Libvirt doesn't support MODIFY for FORWARD_INTERFACE
            false
          end

          def self.save_fragment(new, old, network)
            network.save_fragment(models_cast(new, self), old, :parent_index => -1, :enforce_order => true)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :dev => attrs } if attrs.is_a?(String)
            attrs
          end
        end
      end
    end
  end
end
