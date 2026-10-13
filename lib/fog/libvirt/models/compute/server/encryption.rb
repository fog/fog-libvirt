require "fog/core/model"
require "nokogiri"
require_relative "../common/attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Encryption < AttributeModel
          include Fog::Libvirt::Util

          attribute :format
          attribute :engine

          attribute :secrets, :type => Array

          attribute :cipher
          attribute :ivgen

          def initialize(attributes = {})
            super(normalize_attrs(attributes))
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:format] = attrs[:format].to_sym if attrs[:format]
            attrs[:engine] = attrs[:engine].to_sym if attrs[:engine]

            attrs[:secrets] = node.xpath("secret").map { |secret_node| xml_attrs(secret_node) }
            attrs.delete(:secrets) if attrs[:secrets].empty?

            attrs[:cipher] = xml_attrs(node.at_xpath("cipher"), :autocast_int => true)
            attrs.delete(:cipher) if attrs[:cipher].empty?
            attrs[:ivgen] = xml_attrs(node.at_xpath("ivgen"))
            attrs.delete(:ivgen) if attrs[:ivgen].empty?

            attrs.compact
          end

          def build_xml(xml)
            xml.encryption(attrs_xml(attributes.except(:secrets, :cipher, :ivgen).compact)) do
              secrets.each { |secret| xml.secret(attrs_xml(secret.compact)) }
              xml.cipher(attrs_xml(cipher.compact)) if cipher
              xml.ivgen(attrs_xml(ivgen.compact)) if ivgen
            end
          end

          private

          def normalize_attrs(attrs)
            attrs[:format] = attrs[:format].to_sym unless attrs[:format].to_s.empty?
            attrs[:format] = attrs.delete("format").to_sym unless attrs["format"].to_s.empty?
            attrs[:engine] = attrs[:engine].to_sym unless attrs[:engine].to_s.empty?
            attrs[:engine] = attrs.delete("engine").to_sym unless attrs["engine"].to_s.empty?
            attrs
          end
        end
      end
    end
  end
end
