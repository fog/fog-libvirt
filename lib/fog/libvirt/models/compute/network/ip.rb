require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "dhcp"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Ip < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :address
          attribute :netmask
          attribute :prefix
          attribute :family
          attribute :local_ptr

          attribute :tftp
          attribute :dhcp
          autocast_on_assign :dhcp, Dhcp

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def identity
            [address.to_s, netmask.to_s, prefix.to_s].join("/")
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:prefix] = attrs[:prefix].to_i if attrs.key?(:prefix)
            attrs[:family] = attrs[:family].to_sym if attrs.key?(:family)

            attrs[:tftp] = node.at_xpath("tftp").to_h["root"]
            attrs.delete(:tftp) if attrs[:tftp].nil?

            attrs[:dhcp] = Dhcp.parse_xml(node.at_xpath("dhcp"))
            attrs.delete(:dhcp) unless attrs[:dhcp]

            attrs
          end

          def build_xml(xml)
            attrs = attrs_xml(hash_except(attributes, :dhcp, :tftp))
            xml.ip(attrs.compact.transform_values(&:to_s)) do
              xml.tftp(:root => tftp.to_s) if tftp
              dhcp&.build_xml(xml)
            end
          end

          def fragment_only?(other)
            hash_except(attributes, :dhcp) == hash_except(other.attributes, :dhcp)
          end

          def self.fragment_only?(new_items, old_items)
            return false unless new_items.to_a.length == old_items.to_a.length

            old_by_id = old_items.to_h { |ip| [ip.identity, ip] }
            new_by_id = new_items.to_h do |ip|
              ip = cast(ip)
              [ip.identity, ip]
            end

            return false unless old_by_id.keys == new_by_id.keys

            new_by_id.all? do |id, new|
              old = old_by_id[id]
              new.fragment_only?(old) && Dhcp.fragment_only?(new.dhcp, old.dhcp)
            end
          end

          def self.save_fragment(new_items, old_items, network)
            old_by_id = old_items.each_with_index.to_h { |ip, index| [ip.identity, [ip, index]] }

            updated = false
            new_items.each do |new|
              new = cast(new)
              old = old_by_id[new.identity]
              updated |= Dhcp.save_fragment(new.dhcp, old.first.dhcp, old.last, network)
            end
            updated
          end

          private

          def normalize_attrs(attrs)
            attrs = { :address => attrs.to_s } unless attrs.is_a?(Hash)
            attrs[:prefix] = attrs[:prefix].to_i unless attrs[:prefix].to_s.empty?
            attrs[:prefix] = attrs.delete("prefix").to_i unless attrs["prefix"].to_s.empty?
            attrs[:family] = attrs[:family].to_sym unless attrs[:family].to_s.empty?
            attrs[:family] = attrs.delete("family").to_sym unless attrs["family"].to_s.empty?
            attrs_underscore(attrs)
          end
        end
      end
    end
  end
end
