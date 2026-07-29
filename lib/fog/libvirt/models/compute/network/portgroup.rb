require "fog/core/model"
require_relative "../util/util"
require_relative "../clonable_model"
require_relative "bandwidth"
require_relative "virtualport"
require_relative "vlan"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Portgroup < Fog::Model
          include Fog::Libvirt::Util
          include ClonableModel

          identity :name
          attribute :default
          attribute :trust_guest_rx_filters

          attribute :bandwidth
          attribute :virtualport
          attribute :vlan

          autocast_on_assign :bandwidth, Bandwidth
          autocast_on_assign :virtualport, Virtualport
          autocast_on_assign :vlan, Vlan

          def initialize(attributes = {})
            super(attrs_underscore(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)

            attrs[:bandwidth] = Bandwidth.parse_xml(node.at_xpath("bandwidth"))
            attrs.delete(:bandwidth) unless attrs[:bandwidth]

            attrs[:virtualport] = Virtualport.parse_xml(node.at_xpath("virtualport"))
            attrs.delete(:virtualport) unless attrs[:virtualport]

            attrs[:vlan] = Vlan.parse_xml(node.at_xpath("vlan"))
            attrs.delete(:vlan) unless attrs[:vlan]

            attrs
          end

          def build_xml(xml)
            attrs = attrs_xml(hash_except(attributes, :bandwidth, :virtualport, :vlan))
            xml.portgroup(attrs.compact) do
              bandwidth&.build_xml(xml)
              virtualport&.build_xml(xml)
              vlan&.build_xml(xml)
            end
          end

          def section
            :portgroup
          end

          def self.fragment_only?(new, old)
            true
          end

          def self.save_fragment(new_items, old_items, network)
            network.save_fragment(models_cast(new_items, self), old_items.to_a)
          end
        end
      end
    end
  end
end
