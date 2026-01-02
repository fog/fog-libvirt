require 'fog/core/model'

module Fog
  module Libvirt
    class Compute
      class TPM < Fog::Model
        # Currently Qemu only allows for one TPM device

        identity  :id
        attribute :model
        attribute :type
        attribute :version
        attribute :device_path
        attribute :spapr_address_type
        attribute :spapr_address_reg

        # Models
        #   crb - TCG PC Client Platform TPM Profile (PTP) Specification (2017)
        #   tis - TCG PC Client Specific TPM Interface Specification (TIS) (2013)
        #   spapr - Used with pSeries (ppc64)
        #   spapr-tpm-proxy - Used with pSeries (ppc64), this is only used with 'passthrough' type
        #
        MODELS = ['crb', 'tis', 'spapr', 'spapr-tpm-proxy']

        # Versions
        #
        VERSIONS = ['1.2', '2.0']

        # Types
        #
        TYPES = ['emulator', 'passthrough']

        def initialize(attributes={})
          super defaults.merge(attributes)
          raise Fog::Errors::Error.new("#{model} is not a supported tpm model") if new? && !MODELS.include?(model) 
          raise Fog::Errors::Error.new("#{type} is not a supported tpm type") if new? && !TYPES.include?(type)
        end

        def new?
          id.nil?
        end

        def save
          raise Fog::Errors::Error.new('Creating a new tpm device is not yet implemented. Contributions welcome!')
        end

        def destroy
          raise Fog::Errors::Error.new('Destroying a tpm device is not yet implemented. Contributions welcome!')
        end

        def defaults
          {
            :model => "crb",
            :type => "emulator",
            :version => "2.0",
            :device_path => "/dev/tpm0",
            :spapr_address_type => "spapr-vio",
            :spapr_address_reg => "0x00004000"
          }
        end
      end
    end
  end
end