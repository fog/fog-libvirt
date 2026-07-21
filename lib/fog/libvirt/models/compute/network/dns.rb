require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"
require_relative "dns_forwarder"
require_relative "dns_txt"
require_relative "dns_host"
require_relative "dns_srv"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Dns < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :enable
          attribute :forward_plain_names
          attribute :forwarders, :type => Array
          attribute :hosts, :type => Array
          attribute :txts, :type => Array
          attribute :srvs, :type => Array

          autocast_on_assign :forwarders, [DnsForwarder]
          autocast_on_assign :hosts, [DnsHost]
          autocast_on_assign :txts, [DnsTxt]
          autocast_on_assign :srvs, [DnsSrv]

          def initialize(attributes = {})
            super(attrs_underscore(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)

            attrs[:forwarders] = node.xpath("forwarder").map { |forwarder_node| DnsForwarder.parse_xml(forwarder_node) }
            attrs.delete(:forwarders) if attrs[:forwarders].empty?

            attrs[:hosts] = node.xpath("host").map { |host_node| DnsHost.parse_xml(host_node) }
            attrs.delete(:hosts) if attrs[:hosts].empty?

            attrs[:txts] = node.xpath("txt").map { |txt_node| DnsTxt.parse_xml(txt_node) }
            attrs.delete(:txts) if attrs[:txts].empty?

            attrs[:srvs] = node.xpath("srv").map { |srv_node| DnsSrv.parse_xml(srv_node) }
            attrs.delete(:srvs) if attrs[:srvs].empty?

            attrs
          end

          def build_xml(xml)
            attrs = attrs_xml(hash_except(attributes, :forwarders, :hosts, :txts, :srvs))
            xml.dns(attrs.compact) do
              forwarders.each { |forwarder| model_cast(forwarder, DnsForwarder).build_xml(xml) }
              hosts.each { |host| model_cast(host, DnsHost).build_xml(xml) }
              txts.each { |txt| model_cast(txt, DnsTxt).build_xml(xml) }
              srvs.each { |srv| model_cast(srv, DnsSrv).build_xml(xml) }
            end
          end

          def fragment_only?(other)
            hash_except(attributes, :forwarders, :hosts, :txts, :srvs) == hash_except(other.attributes, :forwarders, :hosts, :txts, :srvs) &&
              models_equal?(forwarders, other.forwarders)
          end

          def self.fragment_only?(new, old)
            old ||= self.new
            new ||= self.new
            new.fragment_only?(old)
          end

          def self.save_fragment(new, old, network)
            return false if old.nil? && new.nil?

            old ||= self.new
            new ||= self.new
            updated = false
            updated |= DnsHost.save_fragment(new.hosts, old.hosts, network)
            updated |= DnsTxt.save_fragment(new.txts, old.txts, network)
            updated |= DnsSrv.save_fragment(new.srvs, old.srvs, network)
            updated
          end
        end
      end
    end
  end
end
