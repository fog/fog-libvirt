require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DnsSrv < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :service
          attribute :protocol
          attribute :domain
          attribute :target
          attribute :port, :type => Integer
          attribute :priority, :type => Integer
          attribute :weight, :type => Integer

          def ==(other)
            return super unless other.is_a?(DnsSrv)

            service == other.service &&
              protocol == other.protocol &&
              domain == other.domain &&
              target == other.target
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = xml_attrs(node)
            attrs[:port] = attrs[:port].to_i if attrs.key?(:port)
            attrs[:priority] = attrs[:priority].to_i if attrs.key?(:priority)
            attrs[:weight] = attrs[:weight].to_i if attrs.key?(:weight)
            attrs
          end

          def build_xml(xml)
            xml.srv(attributes.compact)
          end

          def section
            :dns_srv
          end

          def update_modify?(_service)
            # Libvirt doesn't support MODIFY for DNS_SRV
            false
          end

          def self.save_fragment(new, old, network)
            network.save_fragment(models_cast(new, self), old)
          end
        end
      end
    end
  end
end
