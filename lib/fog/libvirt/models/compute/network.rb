require 'fog/core/model'
require 'fog/libvirt/models/compute/util/util'
require 'fog/libvirt/models/compute/network/bandwidth'
require 'fog/libvirt/models/compute/network/bridge'
require 'fog/libvirt/models/compute/network/dhcp'
require 'fog/libvirt/models/compute/network/dns'
require 'fog/libvirt/models/compute/network/dnsmasq'
require 'fog/libvirt/models/compute/network/domain'
require 'fog/libvirt/models/compute/network/forward'
require 'fog/libvirt/models/compute/network/ip'
require 'fog/libvirt/models/compute/network/portgroup'
require 'fog/libvirt/models/compute/network/route'
require 'fog/libvirt/models/compute/network/virtualport'
require 'fog/libvirt/models/compute/network/vlan'
require 'fog/libvirt/models/compute/clonable_model'
require 'nokogiri'

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        include Fog::Libvirt::Util
        include ClonableModel

        identity :uuid

        attribute :persistent
        attribute :active
        attribute :autostart

        attribute :ipv6
        attribute :trust_guest_rx_filters

        attribute :name
        attribute :metadata
        attribute :title
        attribute :description
        attribute :bridge
        attribute :mtu
        attribute :domain
        attribute :forward
        attribute :bandwidth
        attribute :virtualport
        attribute :vlan
        attribute :portgroups, :type => Array
        attribute :isolated
        attribute :mac
        attribute :dns
        attribute :ips, :type => Array
        attribute :routes, :type => Array
        attribute :dnsmasq

        autocast_on_assign :bridge, Bridge
        autocast_on_assign :domain, Domain
        autocast_on_assign :forward, Forward
        autocast_on_assign :bandwidth, Bandwidth
        autocast_on_assign :virtualport, Virtualport
        autocast_on_assign :vlan, Vlan
        autocast_on_assign :portgroups, [Portgroup]
        autocast_on_assign :dns, Dns
        autocast_on_assign :ips, [Ip]
        autocast_on_assign :routes, [Route]
        autocast_on_assign :dnsmasq, Dnsmasq

        attr_reader :xml

        def initialize(attributes = {})
          @xml = attributes.delete(:xml)
          preloaded = attributes.delete(:preloaded)
          super(defaults.merge(attrs_underscore(attributes)))
          @saved_attributes = preloaded ? Marshal.load(Marshal.dump(self.attributes)) : nil
        end

        def bridge_name
          bridge&.name
        end

        def bridge_name=(name)
          return if name.to_s.empty?

          self.bridge = Bridge.new(:name => name) if bridge.nil?
          bridge.name = name
        end

        def active?
          !!(@saved_attributes.nil? ? active : @saved_attributes[:active])
        end

        def autostart?
          !!(@saved_attributes.nil? ? autostart : @saved_attributes[:autostart])
        end

        def persistent?
          !!(@saved_attributes.nil? ? persistent : @saved_attributes[:persistent])
        end

        def save
          requires :name
          update_network
          reload
        end

        def reload
          requires :identity

          object = collection.get(identity)

          return unless object

          merge_attributes(object.all_associations_and_attributes)

          @xml = object.xml
          @saved_attributes = Marshal.load(Marshal.dump(attributes))
          self
        end

        def start
          return self if active?

          service.client.lookup_network_by_uuid(uuid).create
          reload
          true
        end

        def shutdown
          return unless active?

          service.destroy_network(uuid)
          if persistent?
            reload
          else
            @saved_attributes = { :active => false, :persistent => false }
            self.uuid = nil
            self.active = true
            self.persistent = false
          end
          true
        end

        alias stop shutdown

        def destroy
          shutdown
          if persistent?
            service.client.lookup_network_by_uuid(uuid).undefine if uuid
            @saved_attributes = { :active => false, :persistent => false }
            self.uuid = nil
            self.active = false
            self.persistent = true
          end
          true
        end

        def enable_autostart
          service.update_network_autostart(uuid, true)
          self.autostart = true
          @saved_attributes[:autostart] = autostart if @saved_attributes
        end

        def disable_autostart
          service.update_network_autostart(uuid, false)
          self.autostart = false
          @saved_attributes[:autostart] = autostart if @saved_attributes
        end

        def dhcp_leases(mac, flags = 0)
          service.dhcp_leases(uuid, mac, flags)
        end

        def self.parse_xml(xml)
          node = find_xml_network(xml)
          return nil unless node

          attrs = xml_attrs(node)
          attrs[:xml] = node.to_xml

          parse_xml_general(attrs, node)
          parse_xml_models(attrs, node)
          parse_xml_various(attrs, node)
          parse_xml_lists(attrs, node)

          attrs.compact
        end

        def self.find_xml_network(xml)
          return nil unless xml

          xml = Nokogiri::XML(xml) unless xml.is_a?(Nokogiri::XML::Node)
          return xml unless xml.is_a?(Nokogiri::XML::Document)

          xml.at_xpath("//network")
        end

        private_class_method def self.parse_xml_general(attrs, node)
          attrs[:name] = node.at_xpath("name")&.content
          attrs[:uuid] = node.at_xpath("uuid")&.content
          attrs[:title] = node.at_xpath("title")&.content
          attrs[:description] = node.at_xpath("description")&.content
          attrs[:metadata] = node.at_xpath("metadata")&.to_xml
        end

        private_class_method def self.parse_xml_models(attrs, node)
          attrs[:forward] = Forward.parse_xml(node.at_xpath("forward"))
          attrs[:bridge] = Bridge.parse_xml(node.at_xpath("bridge"))
          attrs[:domain] = Domain.parse_xml(node.at_xpath("domain"))
          attrs[:dns] = Dns.parse_xml(node.at_xpath("dns"))
          attrs[:vlan] = Vlan.parse_xml(node.at_xpath("vlan"))
          attrs[:bandwidth] = Bandwidth.parse_xml(node.at_xpath("bandwidth"))
          attrs[:virtualport] = Virtualport.parse_xml(node.at_xpath("virtualport"))
          attrs[:dnsmasq] = Dnsmasq.parse_xml(node.at_xpath("dnsmasq:options", :dnsmasq => Dnsmasq::NAMESPACE))
          attrs.delete(:dnsmasq) if attrs[:dnsmasq].nil?
        end

        private_class_method def self.parse_xml_various(attrs, node)
          mtu_node = node.at_xpath("mtu")
          attrs[:mtu] = mtu_node["size"]&.to_i if mtu_node

          mac_node = node.at_xpath("mac")
          attrs[:mac] = mac_node["address"] if mac_node

          attrs[:isolated] = xml_attrs(node.at_xpath("port"))[:isolated]
          attrs.delete(:isolated) if attrs[:isolated].nil?
        end

        private_class_method def self.parse_xml_lists(attrs, node)
          attrs[:ips] = node.xpath("ip").map { |ip| Ip.parse_xml(ip) }
          attrs.delete(:ips) if attrs[:ips].empty?

          attrs[:routes] = node.xpath("route").map { |route| Route.parse_xml(route) }
          attrs.delete(:routes) if attrs[:routes].empty?

          attrs[:portgroups] = node.xpath("portgroup").map { |portgroup| Portgroup.parse_xml(portgroup) }
          attrs.delete(:portgroups) if attrs[:portgroups].empty?
        end

        def to_xml
          document, network = prepare_xml_document

          attrs_xml(attributes.slice(:ipv6, :trust_guest_rx_filters).compact).each { |name, value| network[name] = value }

          Nokogiri::XML::Builder.with(network) do |xml|
            build_xml_general(xml)
            build_xml_content1(xml)
            build_xml_content2(xml)
            build_xml_lists(xml)
          end

          document.to_xml
        end

        # Apply partial update using libvirt section updates for changed attributes
        def save_fragment(new_items, old_items, parent_index: -1, enforce_order: false)
          item_to_xml = ->(item) { Nokogiri::XML::Builder.new { |xml| item.build_xml(xml) }.to_xml }

          updated = false
          changes = changeset(new_items, old_items, :enforce_order => enforce_order)

          changes[:modify].each do |item|
            service.update_network_section(uuid, :modify, item.section, item_to_xml.call(item), { :parent_index => parent_index, :persist => persistent?, :live => active? })
            updated = true
          end

          changes[:remove].each do |item|
            service.update_network_section(uuid, :delete, item.section, item_to_xml.call(item), { :parent_index => parent_index, :persist => persistent?, :live => active? })
            updated = true
          end

          changes[:add].each do |item|
            service.update_network_section(uuid, :add_last, item.section, item_to_xml.call(item), { :parent_index => parent_index, :persist => persistent?, :live => active? })
            updated = true
          end

          updated
        end

        def dup
          copy = super
          copy.name = "#{copy.name}-copy"
          copy.instance_variable_set(:@saved_attributes, nil)
          copy.active = false
          copy
        end

        private

        def defaults
          {
            :persistent => true,
            :active => false,
            :autostart => false
          }
        end

        def prepare_xml_document
          if @xml
            document = Nokogiri::XML(@xml)
            network = remove_managed_xml_items(document.at_xpath("//network"))
          end

          unless network
            document = Nokogiri::XML::Document.new
            network = Nokogiri::XML::Node.new("network", document)
            document.add_child(network)
          end

          [document, network]
        end

        def remove_managed_xml_items(network)
          return nil unless network

          %w[ipv6 trust_guest_rx_filters connections].each { |attr| network.delete(attr_camelcase(attr)) }
          hash_except(attributes, :ipv6, :trust_guest_rx_filters, :isolated, :persistent, :active, :autostart).each do |attr, value|
            attr = attr.to_s.chomp("s") if value.is_a?(Array)
            network.xpath(attr.to_s).each(&:remove)
          end
          network.xpath("port").each(&:remove)
          network.xpath("dnsmasq:options", :dnsmasq => Dnsmasq::NAMESPACE).each(&:remove)
          network.xpath("//text()").find_all { |text| text.content.strip.empty? }.map(&:remove)
          network
        end

        def build_xml_general(xml)
          xml.name(name)
          xml.uuid(uuid) if uuid
          xml.title(title) if title
          xml.description(description) if description
          xml << metadata unless metadata.to_s.empty?
        end

        def build_xml_content1(xml)
          forward&.build_xml(xml)
          bridge&.build_xml(xml)
          xml.mtu(:size => mtu) if mtu
          xml.mac(:address => mac) if mac
          domain&.build_xml(xml)
        end

        def build_xml_content2(xml)
          dns&.build_xml(xml)
          vlan&.build_xml(xml)
          bandwidth&.build_xml(xml)

          xml.port(:isolated => value_xml(isolated)) unless isolated.nil?

          virtualport&.build_xml(xml)
          dnsmasq&.build_xml(xml)
        end

        def build_xml_lists(xml)
          ips.each { |ip| model_cast(ip, Ip).build_xml(xml) }
          routes.each { |route| model_cast(route, Route).build_xml(xml) }
          portgroups.each { |pg| model_cast(pg, Portgroup).build_xml(xml) }
        end

        def update_network
          updates = find_updates

          if updates[:fragment]
            perform_fragment_update
          elsif updates[:full]
            perform_full_update
          end

          if updates[:active]
            if active
              service.client.lookup_network_by_uuid(uuid).create
            else
              service.destroy_network(uuid)
            end
          end
          service.update_network_autostart(uuid, autostart) if updates[:autostart]

          self
        end

        def find_updates
          updates = {
            :full => false,
            :fragment => false,
            :active => false,
            :autostart => false
          }

          have_changes = find_partial_updates(updates)
          updates[:full] = have_changes && !updates[:fragment]

          if updates[:full]
            # When performing full update then active and autostart will be updated anyway
            updates[:active] = false
            updates[:autostart] = false
          end

          updates
        end

        # Returns true if there have been any changes
        # comparing with previously saved attributes
        # if no attributes have been saved previously
        # that is considered as having changes
        def find_partial_updates(updates)
          return true unless @saved_attributes

          have_changes = false

          attributes.each_key do |name|
            next if [:active, :autostart].include?(name)
            next if models_equal?(attributes[name], @saved_attributes[name])

            have_changes = true
            updates[:fragment] = fragment_only?(name)
            break unless updates[:fragment]
          end

          # When both are false then we enforce active
          self.active = true if !persistent && !active

          updates[:active] = @saved_attributes[:active] != attributes[:active]
          updates[:autostart] = persistent? && @saved_attributes[:autostart] != attributes[:autostart]

          have_changes
        end

        def perform_fragment_update
          Forward.save_fragment(forward, @saved_attributes[:forward], self)
          Portgroup.save_fragment(portgroups, @saved_attributes[:portgroups], self)
          Dns.save_fragment(dns, @saved_attributes[:dns], self)
          Ip.save_fragment(ips, @saved_attributes[:ips], self)
        end

        def perform_full_update
          current_uuid = @saved_attributes.to_h[:uuid] || uuid
          network = nil
          if current_uuid
            begin
              network = service.client.lookup_network_by_uuid(current_uuid)
            rescue ::Libvirt::RetrieveError
              # not present so will create it
            end
          end
          self.uuid = service.update_network(network, to_xml, persistent, active, autostart).uuid
        end

        # Check if save_fragment could be used for all changes
        def fragment_only?(name)
          case name
          when :forward
            Forward.fragment_only?(forward, @saved_attributes[:forward])
          when :portgroups
            Portgroup.fragment_only?(portgroups, @saved_attributes[:portgroups])
          when :dns
            Dns.fragment_only?(dns, @saved_attributes[:dns])
          when :ips
            Ip.fragment_only?(ips, @saved_attributes[:ips])
          else
            false
          end
        end

        def changeset(new_items, old_items, enforce_order: false)
          changes = {
            :modify => [],
            :remove => old_items.dup,
            :add => []
          }

          new_items.each_with_index do |new_item, new_index|
            old_index = old_items.find_index { |old_item| old_item == new_item }
            if old_index
              wrong_order = enforce_order && new_index != old_index
              changeset_modify(changes, new_item, old_items[old_index], wrong_order)
            else
              changes[:add] << new_item
            end
          end

          changes
        end

        def changeset_modify(changes, new_item, old_item, wrong_order)
          if models_equal?(new_item, old_item)
            if wrong_order
              changes[:add] << new_item
            else
              changes[:remove].delete(old_item)
            end
          elsif new_item.respond_to?(:update_modify?) && !new_item.update_modify?(service)
            # libvirt doesn't support modify for some section updates so need to delete/add instead
            changes[:add] << new_item
          else
            changes[:modify] << new_item
            changes[:remove].delete(old_item)
          end
        end
      end
    end
  end
end
