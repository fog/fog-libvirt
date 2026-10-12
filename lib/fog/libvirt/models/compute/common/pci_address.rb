require "fog/core/model"
require_relative "address"

module Fog
  module Libvirt
    class Compute
      class PciAddress < Fog::Libvirt::Compute::Address
        attribute :domain
        attribute :bus
        attribute :slot
        attribute :function
        attribute :multifunction

        def initialize(attributes = {})
          super(defaults.merge(attributes))
        end

        private

        def defaults
          { :type => "pci", :domain => 0 }
        end
      end
    end
  end
end
