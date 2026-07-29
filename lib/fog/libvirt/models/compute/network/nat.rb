require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Nat < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :ipv6

          attribute :address
          attribute :port

          remove_method :address=

          def address=(address)
            attributes[:address] = if address.is_a?(Range)
                                     normalize_ip_range(address)
                                   else
                                     address
                                   end
          end

          remove_method :port=

          def port=(port)
            if port.is_a?(Range)
              attributes[:port] = normalize_number_range(port)
            else
              attributes[:port] = port
              attributes[:port][:start] = attributes[:port][:start].to_i unless attributes[:port].to_h[:start].to_s.empty?
              attributes[:port][:end] = attributes[:port][:end].to_i unless attributes[:port].to_h[:end].to_s.empty?
            end
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)

            attrs[:address] = xml_attrs(node.at_xpath("address"))
            attrs.delete(:address) if attrs[:address].empty?

            attrs[:port] = xml_attrs(node.at_xpath("port"))
            attrs.delete(:port) if attrs[:port].empty?

            attrs
          end

          def build_xml(xml)
            xml.nat(attrs_xml(hash_except(attributes, :address, :port)).compact) do
              xml.address(address.compact) if address
              xml.port(port.compact) if port
            end
          end
        end
      end
    end
  end
end
