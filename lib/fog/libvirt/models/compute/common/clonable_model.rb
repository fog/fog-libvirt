require "fog/core/model"

module Fog
  module Libvirt
    class Compute
      module ClonableModel
        def clone
          copy = super
          copy.instance_variable_set(:@attributes, Marshal.load(Marshal.dump(attributes)))
          copy
        end

        def dup
          copy = super
          copy.instance_variable_set(:@attributes, Marshal.load(Marshal.dump(attributes)))
          copy.identity = nil if copy.respond_to?(:identity=)
          copy
        end
      end
    end
  end
end
