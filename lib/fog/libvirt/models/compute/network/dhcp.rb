require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "dhcp_range"
require_relative "dhcp_host"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Dhcp < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :ranges, :type => Array
          attribute :hosts, :type => Array
          attribute :bootp

          autocast_on_assign :ranges, [DhcpRange]
          autocast_on_assign :hosts, [DhcpHost]

          remove_method :bootp=

          def bootp=(bootp)
            attributes[:bootp] = if bootp.nil? || bootp.is_a?(Hash)
                                   bootp
                                 else
                                   { :file => bootp.to_s }
                                 end
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = {}
            attrs[:ranges] = node.xpath("range").map { |range_node| DhcpRange.parse_xml(range_node) }
            attrs.delete(:ranges) if attrs[:ranges].empty?

            attrs[:hosts] = node.xpath("host").map { |host_node| DhcpHost.parse_xml(host_node) }
            attrs.delete(:hosts) if attrs[:hosts].empty?

            attrs[:bootp] = xml_attrs(node.at_xpath("bootp"))
            attrs.delete(:bootp) if attrs[:bootp].empty?

            attrs
          end

          def build_xml(xml)
            xml.dhcp do
              ranges.each { |range| DhcpRange.cast(range).build_xml(xml) }
              hosts.each { |host| DhcpHost.cast(host).build_xml(xml) }
              xml.bootp(bootp.compact) if bootp
            end
          end

          def fragment_only?(other)
            bootp == other.bootp
          end

          def self.fragment_only?(new, old)
            old ||= self.new
            new ||= self.new
            new.fragment_only?(old)
          end

          def self.save_fragment(new, old, parent_index, network)
            return false if old.nil? && new.nil?

            old ||= self.new
            new ||= self.new
            updated = false
            updated |= DhcpRange.save_fragment(new.ranges, old.ranges, parent_index, network)
            updated |= DhcpHost.save_fragment(new.hosts, old.hosts, parent_index, network)
            updated
          end
        end
      end
    end
  end
end
