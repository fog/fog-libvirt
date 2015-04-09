require 'fog/core'
require 'fog/xml'
require 'fog/json'
require 'libvirt'

require 'fog/libvirt/version'
require 'fog/libvirt/compute'

module Fog
  module Libvirt
    extend Fog::Provider

    service(:compute, 'Compute')
  end
end
