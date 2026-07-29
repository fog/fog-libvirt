require "fog/core/model"
require_relative "../attribute_model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class Bandwidth < Fog::Libvirt::Compute::AttributeModel
          include Fog::Libvirt::Util

          attribute :inbound
          attribute :outbound

          remove_method :inbound=

          def inbound=(average)
            attributes[:inbound] = if average.is_a?(String) || average.is_a?(Integer)
                                     { :average => average.to_i }
                                   else
                                     average
                                   end
          end

          remove_method :outbound=

          def outbound=(average)
            attributes[:outbound] = if average.is_a?(String) || average.is_a?(Integer)
                                      { :average => average.to_i }
                                    else
                                      average
                                    end
          end

          def self.parse_xml(node)
            return nil unless node

            attrs = {}
            attrs[:inbound] = xml_attrs(node.at_xpath("inbound")).compact.transform_values(&:to_i)
            attrs.delete(:inbound) if attrs[:inbound].empty?

            attrs[:outbound] = xml_attrs(node.at_xpath("outbound")).compact.transform_values(&:to_i)
            attrs.delete(:outbound) if attrs[:outbound].empty?

            attrs
          end

          def build_xml(xml)
            xml.bandwidth do
              xml.inbound(inbound.compact) unless inbound.to_h.empty?
              xml.outbound(outbound.compact) unless outbound.to_h.empty?
            end
          end
        end
      end
    end
  end
end
