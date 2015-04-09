require 'fog/core'
require 'fog/xml'
require 'fog/json'
require 'libvirt'

module Fog
  module Libvirt
    extend Fog::Provider

    service(:compute, 'Compute')
  end
end
