require "fog/core/model"
require_relative "clonable_model"

module Fog
  module Libvirt
    class Compute
      class AttributeModel < Fog::Model
        include ClonableModel

        def initialize(attributes = {}) # rubocop:disable Lint/MissingSuper
          # don't call super because we want to allow regular :service attribute
          merge_attributes(attributes)
        end

        def self.cast(item)
          return item if item.is_a?(self)

          new(item)
        end

        def ==(other)
          return super unless other.is_a?(Fog::Model)
          return false unless self.class == other.class

          other.attributes.compact == attributes.compact
        end

        def hash
          attributes.compact.hash
        end

        def eql?(other)
          self == other
        end
      end
    end
  end
end
