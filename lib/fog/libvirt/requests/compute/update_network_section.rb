module Fog
  module Libvirt
    class Compute
      module Shared
        def update_network_section(uuid, command, section, xml, options = {})
          network = client.lookup_network_by_uuid(uuid)
          parent_index = options.fetch(:parent_index, -1)
          flags = network_update_flags(options)
          network.update(network_update_command(command), network_section_id(section), parent_index, xml, flags)
          true
        end

        private

        def network_update_command(command)
          case command
          when :modify then ::Libvirt::Network::UPDATE_COMMAND_MODIFY
          when :add_last then ::Libvirt::Network::UPDATE_COMMAND_ADD_LAST
          when :add_first then ::Libvirt::Network::UPDATE_COMMAND_ADD_FIRST
          when :delete then ::Libvirt::Network::UPDATE_COMMAND_DELETE
          else raise ArgumentError, "Unknown update command: #{command}"
          end
        end

        def network_section_id(section)
          case section
          when :dhcp_range then ::Libvirt::Network::SECTION_IP_DHCP_RANGE
          when :dhcp_host then ::Libvirt::Network::SECTION_IP_DHCP_HOST
          when :forward_interface then ::Libvirt::Network::SECTION_FORWARD_INTERFACE
          when :portgroup then ::Libvirt::Network::SECTION_PORTGROUP
          when :dns_host then ::Libvirt::Network::SECTION_DNS_HOST
          when :dns_txt then ::Libvirt::Network::SECTION_DNS_TXT
          when :dns_srv then ::Libvirt::Network::SECTION_DNS_SRV
          else raise ArgumentError, "Unknown or unsupported section: #{section}"
          end
        end

        def network_update_flags(options = {})
          flags = 0
          flags |= ::Libvirt::Network::UPDATE_AFFECT_LIVE if options.fetch(:live, false)
          flags |= ::Libvirt::Network::UPDATE_AFFECT_CONFIG if options.fetch(:persist, false)
          flags
        end
      end

      class Real
        include Shared
      end

      class Mock
        include Shared
      end
    end
  end
end
