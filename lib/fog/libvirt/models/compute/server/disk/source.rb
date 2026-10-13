require "fog/core/model"
require "nokogiri"
require_relative "../../common/attribute_model"
require_relative "../../common/address"
require_relative "../../util/util"
require_relative "../seclabel"
require_relative "../encryption"
require_relative "source/data_store"
require_relative "source/reservations"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Source < AttributeModel
            include Fog::Libvirt::Util

            # disk type = file
            attribute :file
            attribute :fdgroup

            # disk type = block
            attribute :dev

            # disk type = dir
            attribute :dir

            # disk type = network
            attribute :protocol
            attribute :name
            attribute :tls
            attribute :tls_hostname
            attribute :query

            # disk type = volume
            attribute :pool
            attribute :volume
            attribute :mode

            # disk type = nvme
            attribute :type
            attribute :managed
            attribute :namespace

            # disk type = vhostuser
            # :type
            attribute :path

            attribute :startup_policy

            attribute :seclabels, :type => Array
            attribute :hosts, :type => Array

            attribute :snapshot
            attribute :config

            attribute :auth
            attribute :encryption
            attribute :reservations
            attribute :initiator

            attribute :address
            attribute :slices, :type => Array
            attribute :ssl_verify
            attribute :cookies, :type => Array

            attribute :readahead, :type => Integer
            attribute :timeout, :type => Integer

            attribute :identity
            attribute :reconnect
            attribute :known_hosts
            attribute :data_store

            autocast_on_assign :seclabels, [Seclabel]
            autocast_on_assign :encryption, Encryption
            autocast_on_assign :reservations, Reservations
            autocast_on_assign :address, Address
            autocast_on_assign :data_store, DataStore

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node)

              parse_xml_various(attrs, node)
              parse_xml_auth(attrs, node)
              parse_xml_cookies(attrs, node)
              parse_xml_standalone(attrs, node)
              parse_xml_models(attrs, node)
              parse_xml_reconnect(attrs, node)

              attrs.compact
            end

            private_class_method def self.parse_xml_various(attrs, node)
              attrs[:hosts] = node.xpath("host").map { |host_node| xml_attrs(host_node, :autocast_int => true) }
              attrs.delete(:hosts) if attrs[:hosts].empty?

              attrs[:slices] = node.xpath("slice").map { |slice_node| xml_attrs(slice_node, :autocast_int => true) }
              attrs.delete(:slices) if attrs[:slices].empty?

              attrs[:identity] = xml_attrs(node.at_xpath("identity"))
              attrs.delete(:identity) if attrs[:identity].empty?
            end

            private_class_method def self.parse_xml_auth(attrs, node)
              return unless node

              auth_node = node.at_xpath("auth")
              return unless auth_node

              attrs[:auth] = xml_attrs(auth_node)
              attrs[:auth][:secret] = xml_attrs(auth_node.at_xpath("secret"))
              attrs[:auth].delete(:secret) if attrs[:auth][:secret].empty?

              attrs[:auth]
            end

            private_class_method def self.parse_xml_cookies(attrs, node)
              return unless node

              cookies = node.xpath("cookies/cookie").map do |cookie_node|
                cookie = xml_attrs(cookie_node)
                cookie[:value] = cookie_node.content
                cookie
              end

              return if cookies.empty?

              attrs[:cookies] = cookies
            end

            private_class_method def self.parse_xml_standalone(attrs, node)
              attrs[:snapshot] = xml_attrs(node.at_xpath("snapshot"))[:name]
              attrs[:config] = xml_attrs(node.at_xpath("config"))[:file]
              attrs[:initiator] = xml_attrs(node.at_xpath("initiator/iqn"))[:name]
              attrs[:ssl_verify] = xml_attrs(node.at_xpath("ssl"))[:verify]
              attrs[:readahead] = xml_attrs(node.at_xpath("readahead"))[:size]&.to_i
              attrs[:timeout] = xml_attrs(node.at_xpath("timeout"))[:seconds]&.to_i
              attrs[:known_hosts] = xml_attrs(node.at_xpath("knownHosts"))[:path]
            end

            private_class_method def self.parse_xml_models(attrs, node)
              attrs[:seclabels] = node.xpath("seclabel").map { |seclabel_node| Seclabel.parse_xml(seclabel_node) }
              attrs.delete(:seclabels) if attrs[:seclabels].empty?

              attrs[:address] = Address.parse_xml(node.at_xpath("address"))
              attrs[:encryption] = Encryption.parse_xml(node.at_xpath("encryption"))
              attrs[:reservations] = Reservations.parse_xml(node.at_xpath("reservations"))
              attrs[:data_store] = DataStore.parse_xml(node.at_xpath("dataStore"))
            end

            private_class_method def self.parse_xml_reconnect(attrs, node)
              return unless node

              reconnect_node = node.at_xpath("reconnect")
              return unless reconnect_node

              attrs[:reconnect] = xml_attrs(reconnect_node)
              attrs[:reconnect][:timeout] = attrs[:reconnect][:timeout].to_i if attrs[:reconnect][:timeout]
              attrs[:reconnect][:delay] = attrs[:reconnect][:delay].to_i if attrs[:reconnect][:delay]
            end

            # read-only
            def index
              attributes[:index]
            end

            def build_xml(xml)
              non_attrs = [:index, :seclabels, :hosts, :snapshot, :config, :auth, :encryption,
                           :reservations, :initiator, :address, :slices, :ssl_verify,
                           :cookies, :readahead, :timeout, :identity, :reconnect,
                           :known_hosts, :data_store]
              xml.source(attrs_xml(attributes.except(*non_attrs).compact)) do
                build_xml_models(xml)
                build_xml_various(xml)
                build_xml_standalone(xml)
                build_xml_auth(xml)
                build_xml_initiator(xml)
                build_xml_cookies(xml)
                build_xml_reconnect(xml)
              end
            end

            private

            def build_xml_models(xml)
              address&.build_xml(xml)
              seclabels.each { |seclabel| model_cast(seclabel, Seclabel).build_xml(xml) }
              encryption&.build_xml(xml)
              reservations&.build_xml(xml)
              data_store&.build_xml(xml)
            end

            def build_xml_various(xml)
              hosts.each { |host| xml.host(attrs_xml(host.compact)) }
              slices.each { |slice| xml.slice(attrs_xml(slice.compact)) }
              xml.identity(attrs_xml(attributes[:identity].compact)) if attributes[:identity]
            end

            def build_xml_standalone(xml)
              xml.snapshot(:name => snapshot) if snapshot
              xml.config(:file => config) if config
              xml.ssl(:verify => value_xml(ssl_verify)) unless ssl_verify.nil?
              xml.readahead(:size => readahead) unless readahead.to_i.zero?
              xml.timeout(:seconds => timeout) unless timeout.to_i.zero?
              xml.knownHosts(:path => known_hosts) if known_hosts
            end

            def build_xml_auth(xml)
              return unless auth

              xml.auth(attrs_xml(auth.except(:secret)).compact) do
                xml.secret(attrs_xml(auth[:secret]).compact)
              end
            end

            def build_xml_initiator(xml)
              return unless initiator

              xml.initiator do
                xml.iqn(:name => initiator)
              end
            end

            def build_xml_cookies(xml)
              return if cookies.to_a.empty?

              xml.cookies do
                cookies.each { |cookie| xml.cookie(attrs_xml(cookie.except(:value).compact), cookie[:value]) }
              end
            end

            def build_xml_reconnect(xml)
              return unless reconnect

              xml.reconnect(attrs_xml(reconnect.compact))
            end
          end
        end
      end
    end
  end
end
