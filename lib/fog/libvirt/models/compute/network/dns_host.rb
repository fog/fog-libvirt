require "fog/core/model"
require_relative "../util/util"
require_relative "../clonable_model"

module Fog
  module Libvirt
    class Compute
      class Network < Fog::Model
        class DnsHost < Fog::Model
          include Fog::Libvirt::Util
          include ClonableModel

          identity :ip
          attribute :hostnames, :type => Array

          def self.parse_xml(node)
            return nil unless node

            { :ip => node["ip"], :hostnames => node.xpath("hostname").map(&:content) }
          end

          def build_xml(xml)
            xml.host(:ip => ip.to_s) do
              hostnames.each { |hostname| xml.hostname(hostname) }
            end
          end

          def section
            :dns_host
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
