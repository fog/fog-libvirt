require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "nat"
require_relative "forward_interface"
require_relative "pci_address"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Forward < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :mode
          attribute :managed

          attribute :nat
          attribute :interfaces, :type => Array
          attribute :pf
          attribute :driver
          attribute :addresses, :type => Array

          autocast_on_assign :nat, Nat
          autocast_on_assign :interfaces, [ForwardInterface]
          autocast_on_assign :addresses, [PciAddress]

          def initialize(attributes = {})
            attrs = normalize_attrs(attributes)
            dev = attrs.delete(:dev)
            super(attrs)
            self.dev = dev if dev
          end

          def dev
            interfaces&.first&.dev
          end

          def dev=(dev)
            if dev.nil?
              attributes[:interfaces] = []
            else
              attributes[:interfaces] ||= []
              interface = attributes[:interfaces].find { |interface| interface.dev == dev }
              if interface
                attributes[:interfaces].unshift(attributes[:interfaces].delete(interface))
              else
                attributes[:interfaces] = [ForwardInterface.new(dev)]
              end
            end
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:mode] = attrs[:mode].to_sym if attrs.key?(:mode)

            attrs[:nat] = Nat.parse_xml(node.at_xpath("nat"))
            attrs.delete(:nat) unless attrs[:nat]

            attrs[:pf] = node.at_xpath("pf").to_h["dev"]
            attrs.delete(:pf) if attrs[:pf].nil?

            attrs[:driver] = node.at_xpath("driver").to_h["model"]
            attrs.delete(:driver) if attrs[:driver].nil?

            parse_xml_lists(attrs, node)

            attrs
          end

          private_class_method def self.parse_xml_lists(attrs, node)
            attrs[:interfaces] = node.xpath("interface").map { |interface_node| ForwardInterface.parse_xml(interface_node) }
            attrs.delete(:interfaces) if attrs[:interfaces].empty?

            attrs[:addresses] = node.xpath("address").map { |address_node| PciAddress.parse_xml(address_node) }
            attrs.delete(:addresses) if attrs[:addresses].empty?
          end

          def build_xml(xml)
            attrs = attrs_xml(hash_except(attributes, :nat, :interfaces, :pf, :driver, :addresses))
            attrs[:dev] = dev

            xml.forward(attrs.compact) do
              nat&.build_xml(xml)
              interfaces.each { |interface| model_cast(interface, ForwardInterface).build_xml(xml) }
              xml.pf(:dev => pf) if pf
              xml.driver(:model => driver) if driver
              addresses.each { |address| model_cast(address, PciAddress).build_xml(xml) }
            end
          end

          def fragment_only?(other)
            hash_except(attributes, :interfaces, :nat, :addresses) == hash_except(other.attributes, :interfaces, :nat, :addresses) &&
              models_equal?(nat, other.nat) && models_equal?(addresses, other.addresses)
          end

          def self.fragment_only?(new, old)
            old ||= self.new
            new ||= self.new
            new.fragment_only?(old)
          end

          def self.save_fragment(new, old, network)
            old ||= self.new
            new ||= self.new
            ForwardInterface.save_fragment(new.interfaces, old.interfaces, network)
          end

          private

          def normalize_attrs(attrs)
            attrs = { :mode => attrs.to_sym } unless attrs.is_a?(Hash)
            attrs
          end
        end
      end
    end
  end
end
