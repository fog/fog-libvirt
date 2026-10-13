require "fog/core/model"
require "nokogiri"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        module Driver
          module Virtio
            def self.included(model)
              model.attribute :iommu
              model.attribute :ats
              model.attribute :packed
              model.attribute :page_per_vq
            end
          end
        end
      end
    end
  end
end
