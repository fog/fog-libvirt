require 'fog/core/model'

module Fog
  module Libvirt
    class Compute
      class TPM < Fog::Model
        # Currently Qemu only allows for one TPM device

        identity  :id
        attribute :arch
        attribute :model
        attribute :type
        attribute :version
        attribute :device_path
        attribute :spapr_address_type
        attribute :spapr_address_reg

        # Types
        #
        TYPES = ['emulator', 'passthrough'].freeze

        # Models
        #   crb - TCG PC Client Platform TPM Profile (PTP) Specification (2017)
        #   tis - TCG PC Client Specific TPM Interface Specification (TIS) (2013)
        #   spapr - Used with pSeries (ppc64)
        #   spapr-tpm-proxy - Used with pSeries (ppc64), this is only used with 'passthrough' type
        #
        MODELS_X86_64 = ['crb', 'tis'].freeze
        MODELS_PPC64 = ['spapr', 'spapr-tpm-proxy'].freeze
        MODELS_ARM64 = ['tis'].freeze
        MODELS_S390X = ['tis'].freeze

        # Versions
        #
        VERSIONS = ['1.2', '2.0'].freeze

        def initialize(arch = "", attributes = {})
          @id = "tpm0"
          @arch = arch
          super defaults.merge(attributes)
          raise Fog::Errors::Error, "#{type} is not a supported TPM type" if new? && !TYPES.include?(type)
          raise Fog::Errors::Error, "#{model} is not a supported TPM model" if new? && !supported_models.include?(model)
          raise Fog::Errors::Error, "TPM model type crb does not a supported TPM version 1.2" if model == "crb" && version == "1.2"
        end

        def new?
          id.nil?
        end

        def save
          raise Fog::Errors::Error, 'Creating a new TPM device is not yet implemented. Contributions welcome!'
        end

        def destroy
          raise Fog::Errors::Error, 'Destroying a TPM device is not yet implemented. Contributions welcome!'
        end

        def supported_models
          case @arch
          when "x86_64"
            MODELS_X86_64
          when "ppc64" || "ppc64le"
            MODELS_PPC64
          when "arm" || "aarch64" || "aarch64_be"
            MODELS_ARM64
          when "s390x"
            MODELS_S390X
          else
            raise Fog::Errors::Error, 'CPU Architecture does not have any supported TPM models!'
          end
        end

        def defaults
          case @arch
          when "x86_64"
            { :model => "crb", :type => "emulator", :version => "2.0", :passthrough_device_path => "/dev/tpm0" }
          when "ppc64" || "ppc64le"
            {
              :model => "spapr",
              :type => "emulator",
              :version => "2.0",
              :passthrough_device_path => "/dev/tpm0",
              :spapr_address_type => "spapr-vio",
              :spapr_address_reg => "0x00004000"
            }
          when "arm" || "aarch64" || "aarch64_be"
            { :model => "tis", :type => "emulator", :version => "2.0", :passthrough_device_path => "/dev/tpm0" }
          when "s390x"
            { :model => "tis", :type => "emulator", :version => "2.0", :passthrough_device_path => "/dev/tpm0" }
          else
            {}
          end
        end
      end
    end
  end
end
