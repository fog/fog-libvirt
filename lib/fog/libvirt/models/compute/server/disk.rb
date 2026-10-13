require "fog/core/model"
require "nokogiri"
require_relative "../common/attribute_model"
require_relative "../common/address"
require_relative "../common/drive_address"
require_relative "../common/pci_address"
require_relative "../util/util"
require_relative "disk/backing_store"
require_relative "disk/driver"
require_relative "disk/mirror"
require_relative "disk/source"
require_relative "disk/target"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          include Fog::Libvirt::Util

          attribute :type
          attribute :device
          attribute :model
          attribute :rawio
          attribute :sgio
          attribute :snapshot

          attribute :source
          attribute :backing_store
          attribute :target
          attribute :throttlefilters, :type => Array
          attribute :iotune
          attribute :driver
          attribute :backenddomain
          attribute :boot
          attribute :readonly
          attribute :shareable
          attribute :transient
          attribute :serial
          attribute :wwn
          attribute :vendor
          attribute :product
          attribute :address
          attribute :geometry
          attribute :blockio

          autocast_on_assign :source, Source
          autocast_on_assign :target, Target
          autocast_on_assign :backing_store, BackingStore
          autocast_on_assign :driver, Driver
          autocast_on_assign :address, Address

          # read-only
          attr_reader :mirror

          def initialize(attributes = {})
            mirror = attributes.delete(:mirror)
            @mirror = Mirror.new(mirror) if mirror
            super(attributes)
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)

            parse_xml_simple(attrs, node)
            parse_xml_various(attrs, node)
            parse_xml_switches(attrs, node)
            parse_xml_models(attrs, node)
            parse_xml_iotune(attrs, node)
            parse_xml_content(attrs, node)

            attrs.compact
          end

          private_class_method def self.parse_xml_simple(attrs, node)
            [:boot, :geometry, :blockio].each do |name|
              attrs[name] = xml_attrs(node.at_xpath(name.to_s), :autocast_int => true)
              attrs.delete(name) if attrs[name].empty?
            end
          end

          private_class_method def self.parse_xml_various(attrs, node)
            attrs[:throttlefilters] = node.xpath("throttlefilters/throttlefilter").map { |throttlefilter_node| xml_attrs(throttlefilter_node)[:group] }
            attrs.delete(:throttlefilters) if attrs[:throttlefilters].empty?

            attrs[:backenddomain] = xml_attrs(node.at_xpath("backenddomain"))[:name]
          end

          private_class_method def self.parse_xml_switches(attrs, node)
            attrs[:readonly] = !node.at_xpath("readonly").nil?
            attrs[:shareable] = !node.at_xpath("shareable").nil?

            transient_node = node.at_xpath("transient")
            attrs[:transient] = xml_attrs(transient_node) if transient_node
          end

          private_class_method def self.parse_xml_models(attrs, node)
            attrs[:target] = Target.parse_xml(node.at_xpath("target"))
            attrs[:address] = Address.parse_xml(node.at_xpath("address"))
            attrs[:source] = Source.parse_xml(node.at_xpath("source"))
            attrs[:backing_store] = BackingStore.parse_xml(node.at_xpath("backingStore"))
            attrs[:mirror] = Mirror.parse_xml(node.at_xpath("mirror"))
            attrs[:driver] = Driver.parse_xml(node.at_xpath("driver"))
          end

          private_class_method def self.parse_xml_content(attrs, node)
            attrs[:serial] = node.at_xpath("serial")&.content
            attrs[:wwn] = node.at_xpath("wwn")&.content
            attrs[:vendor] = node.at_xpath("vendor")&.content
            attrs[:product] = node.at_xpath("product")&.content
          end

          private_class_method def self.parse_xml_iotune(attrs, node)
            return unless node

            iotune_node = node.at_xpath("iotune")
            return unless iotune_node

            attrs[:iotune] = iotune_node.elements.each_with_object({}) do |element, result|
              value = element.content
              result[element.name.to_sym] = value.match?(/^\d+$/) ? value.to_i : value
            end
          end

          def build_xml(xml)
            elements = [:source, :backing_store, :mirror, :target, :throttlefilters, :iotune,
                        :driver, :backenddomain, :boot, :readonly, :shareable, :transient,
                        :serial, :wwn, :vendor, :product, :address, :geometry, :blockio]
            xml.disk(attrs_xml(attributes.except(*elements).compact)) do
              build_xml_various(xml)
              build_xml_switches(xml)
              build_xml_models(xml)
              build_xml_content(xml)
            end
          end

          private

          def build_xml_various(xml)
            unless throttlefilters.empty?
              xml.throttlefilters do
                throttlefilters.each { |throttlefilter| xml.throttlefilter(:group => throttlefilter) }
              end
            end

            xml.backenddomain(:name => backenddomain) if backenddomain
            xml.boot(attrs_xml(boot.compact)) if boot

            xml.geometry(attrs_xml(geometry.compact)) if geometry
            xml.blockio(attrs_xml(blockio.compact, :casing => :snake)) if blockio
          end

          def build_xml_switches(xml)
            xml.readonly if readonly
            xml.shareable if shareable
            xml.transient(attrs_xml(transient.compact)) if transient
          end

          def build_xml_models(xml)
            target&.build_xml(xml)
            address&.build_xml(xml)
            source&.build_xml(xml)
            backing_store&.build_xml(xml)
            driver&.build_xml(xml)
          end

          def build_xml_content(xml)
            if iotune
              xml.iotune do
                iotune.each { |name, value| xml.public_send(name, value) }
              end
            end

            xml.serial(serial) if serial
            xml.wwn(wwn) if wwn
            xml.vendor(vendor) if vendor
            xml.product(product) if product
          end
        end
      end
    end
  end
end
