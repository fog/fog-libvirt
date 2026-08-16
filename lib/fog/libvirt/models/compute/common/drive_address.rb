require "fog/core/model"
require_relative "address"

module Fog
  module Libvirt
    class Compute
      class DriveAddress < Fog::Libvirt::Compute::Address
        attribute :controller
        attribute :bus
        attribute :target
        attribute :unit

        def initialize(attributes = {})
          super(defaults.merge(attributes))
        end

        private

        def defaults
          { :type => "drive" }
        end
      end
    end
  end
end
