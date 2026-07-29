require "fog/core/model"
require_relative "../util/util"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DnsTxt < Fog::Model
          include Fog::Libvirt::Util

          identity :name
          attribute :value

          def self.parse_xml(node)
            return nil unless node

            xml_attrs(node)
          end

          def build_xml(xml)
            xml.txt(attributes.compact)
          end

          def section
            :dns_txt
          end

          def update_modify?(service)
            # support since libvirt >= 10.6.0
            service.client.libversion >= 10_006_000
          end

          def self.save_fragment(new, old, network)
            network.save_fragment(models_cast(new, self), old)
          end
        end
      end
    end
  end
end
