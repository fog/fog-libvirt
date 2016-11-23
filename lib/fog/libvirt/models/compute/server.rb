require 'fog/compute/models/server'
require 'fog/libvirt/models/compute/util/util'
require 'fileutils'

module Fog
  module Compute
    class Libvirt
      class Server < Fog::Compute::Server
        include Fog::Compute::LibvirtUtil
        attr_reader :xml

        identity :id, :aliases => 'uuid'

        attribute :cpus
        attribute :cputime
        attribute :os_type
        attribute :memory_size
        attribute :max_memory_size
        attribute :name
        attribute :arch
        attribute :persistent
        attribute :domain_type
        attribute :uuid
        attribute :autostart
        attribute :nics
        attribute :volumes
        attribute :active
        attribute :boot_order
        attribute :display

        attribute :state

        # The following attributes are only needed when creating a new vm
        #TODO: Add depreciation warning
        attr_accessor :iso_dir, :iso_file
        attr_accessor :network_interface_type ,:network_nat_network, :network_bridge_name
        attr_accessor :volume_format_type, :volume_allocation,:volume_capacity, :volume_name, :volume_pool_name, :volume_template_name, :volume_path
        attr_accessor :password
        attr_accessor :user_data

        # Can be created by passing in :xml => "<xml to create domain/server>"
        # or by providing :template_options => {
        #                :name => "", :cpus => 1, :memory_size => 256 , :volume_template
        #   }

        def initialize(attributes={} )
          @xml = attributes.delete(:xml)
          verify_boot_order(attributes[:boot_order])
          super defaults.merge(attributes)
          initialize_nics
          initialize_volumes
          @user_data = attributes.delete(:user_data)
        end

        def new?
          uuid.nil?
        end

        def save
          raise Fog::Errors::Error.new('Saving an existing server may create a duplicate') unless new?
          create_or_clone_volume unless xml or @volumes
          create_user_data_iso if user_data
          @xml ||= to_xml
          self.id = (persistent ? service.define_domain(xml) : service.create_domain(xml)).uuid
          reload
        rescue => e
          raise Fog::Errors::Error.new("Error saving the server: #{e}")
        end

        def start
          return true if active?
          action_status = service.vm_action(uuid, :create)
          reload
          action_status
        end

        def mac
          nics.first.mac if nics && nics.first
        end

        def disk_path
          volumes.first.path if volumes and volumes.first
        end

        def destroy(options={ :destroy_volumes => false})
          poweroff unless stopped?
          service.vm_action(uuid, :undefine)
          volumes.each { |vol| vol.destroy } if options[:destroy_volumes]
          true
        end

        def reboot
          action_status = service.vm_action(uuid, :reboot)
          reload
          action_status
        end

        def poweroff
          action_status = service.vm_action(uuid, :destroy)
          reload
          action_status
        end

        def shutdown
          action_status = service.vm_action(uuid, :shutdown)
          reload
          action_status
        end

        def resume
          action_status = service.vm_action(uuid, :resume)
          reload
          action_status
        end

        def suspend
          action_status = service.vm_action(uuid, :suspend)
          reload
          action_status
        end

        def stopped?
          state == "shutoff"
        end

        def ready?
          state == "running"
        end

        #alias methods
        alias_method :halt,    :poweroff
        alias_method :stop,    :shutdown
        alias_method :active?, :active

        def volumes
          # lazy loading of volumes
          @volumes ||= (@volumes_path || []).map{|path| service.volumes.all(:path => path).first }
        end

        def private_ip_address
          ip_address(:private)
        end

        def public_ip_address
          ip_address(:public)
        end

        def ssh(commands)
          requires :ssh_ip_address, :username

          ssh_options={}
          ssh_options[:password] = password unless password.nil?
          ssh_options[:proxy]= ssh_proxy unless ssh_proxy.nil?

          super(commands, ssh_options)
        end

        def ssh_proxy
          begin
            require 'net/ssh/proxy/command'
          rescue LoadError
            Fog::Logger.warning("'net/ssh' missing, please install and try again.")
            exit(1)
          end
          # if this is a direct connection, we don't need a proxy to be set.
          return nil unless connection.uri.ssh_enabled?
          user_string= service.uri.user ? "-l #{service.uri.user}" : ""
          Net::SSH::Proxy::Command.new("ssh #{user_string} #{service.uri.host} nc %h %p")
        end

        # Transfers a file
        def scp(local_path, remote_path, upload_options = {})
          requires :ssh_ip_address, :username

          scp_options = {}
          scp_options[:password] = password unless self.password.nil?
          scp_options[:key_data] = [private_key] if self.private_key
          scp_options[:proxy]= ssh_proxy unless self.ssh_proxy.nil?

          Fog::SCP.new(ssh_ip_address, username, scp_options).upload(local_path, remote_path, upload_options)
        end

        # Sets up a new key
        def setup(credentials = {})
          requires :public_key, :ssh_ip_address, :username

          credentials[:proxy]= ssh_proxy unless ssh_proxy.nil?
          credentials[:password] = password unless self.password.nil?
          credentails[:key_data] = [private_key] if self.private_key

          commands = [
            %{mkdir .ssh},
            #              %{passwd -l #{username}}, #Not sure if we need this here
            #              %{echo "#{Fog::JSON.encode(attributes)}" >> ~/attributes.json}
          ]
          if public_key
            commands << %{echo "#{public_key}" >> ~/.ssh/authorized_keys}
          end

          # wait for domain to be ready
          Timeout::timeout(360) do
            begin
              Timeout::timeout(8) do
                Fog::SSH.new(ssh_ip_address, username, credentials.merge(:timeout => 4)).run('pwd')
              end
            rescue Errno::ECONNREFUSED
              sleep(2)
              retry
            rescue Net::SSH::AuthenticationFailed, Timeout::Error
              retry
            end
          end
          Fog::SSH.new(ssh_ip_address, username, credentials).run(commands)
        end

        def update_display attrs = {}
          service.update_display attrs.merge(:uuid => uuid)
          reload
        end

        # can't use deprecate method, as the value is part of the display hash
        def vnc_port
          Fog::Logger.deprecation("#{self.class} => #vnc_port is deprecated, use #display[:port] instead [light_black](#{caller.first})[/]")
          display[:port]
        end

        def generate_config_iso(user_data, &blk)
          Dir.mktmpdir('config') do |wd|
            generate_config_iso_in_dir(wd, user_data, &blk)
          end
        end

        def generate_config_iso_in_dir(dir_path, user_data, &blk)
          FileUtils.touch(File.join(dir_path, "meta-data"))
          File.open(File.join(dir_path, 'user-data'), 'w') { |f| f.write user_data }

          isofile = Tempfile.new(['init', '.iso']).path
          unless system("genisoimage -output #{isofile} -volid cidata -joliet -rock #{File.join(dir_path, 'user-data')} #{File.join(dir_path, 'meta-data')}")
            raise Fog::Errors::Error.new("Couldn't generate cloud-init iso disk with genisoimage.")
          end
          blk.call(isofile)
        end

        def create_user_data_iso
          generate_config_iso(user_data) do |iso|
            vol = service.volumes.create(:name => cloud_init_volume_name, :capacity => "#{File.size(iso)}b", :allocation => "0G")
            vol.upload_image(iso)
            @iso_file = cloud_init_volume_name
            @iso_dir = File.dirname(vol.path) if vol.path
          end
        end

        def cloud_init_volume_name
          "#{name}-cloud-init.iso"
        end

        private
        attr_accessor :volumes_path

        # This retrieves the ip address of the mac address
        # It returns an array of public and private ip addresses
        # Currently only one ip address is returned, but in the future this could be multiple
        # if the server has multiple network interface
        def addresses(service_arg=service, options={})
          mac=self.mac

          ip_address = nil
          nic = self.nics.find {|nic| nic.mac==mac}
          if !nic.nil?
            service.networks.all.each do |net|
              if net.name == nic.network
                leases = net.dhcp_leases(mac, 0)
                # Assume the lease expiring last is the current IP address
                ip_address = leases.sort_by { |lse| lse["expirytime"] }.last["ipaddr"] if !leases.empty?
                break
              end
            end
          end

          return { :public => [ip_address], :private => [ip_address] }
        end

        def ip_address(key)
          addresses[key].nil? ? nil : addresses[key].first
        end

        def initialize_nics
          if nics
            nics.map! { |nic| nic.is_a?(Hash) ? service.nics.new(nic) : nic }
          else
            self.nics = [service.nics.new({:type => network_interface_type, :bridge => network_bridge_name, :network => network_nat_network})]
          end
        end

        def initialize_volumes
          if attributes[:volumes] && !attributes[:volumes].empty?
            @volumes = attributes[:volumes].map { |vol| vol.is_a?(Hash) ? service.volumes.new(vol) : vol }
          end
        end

        def create_or_clone_volume
          options = {:name => volume_name || default_volume_name}
          # Check if a disk template was specified
          if volume_template_name
            template_volume = service.volumes.all(:name => volume_template_name).first
            raise Fog::Errors::Error.new("Template #{volume_template_name} not found") unless template_volume
            begin
              volume = template_volume.clone("#{options[:name]}")
            rescue => e
              raise Fog::Errors::Error.new("Error creating the volume : #{e}")
            end
          else
            # If no template volume was given, let's create our own volume
            options[:pool_name]   = volume_pool_name   if volume_pool_name
            options[:format_type] = volume_format_type if volume_format_type
            options[:capacity]    = volume_capacity    if volume_capacity
            options[:allocation]  = volume_allocation  if volume_allocation

            begin
              volume = service.volumes.create(options)
            rescue => e
              raise Fog::Errors::Error.new("Error creating the volume : #{e}")
            end
          end
          @volumes.nil? ? @volumes = [volume] : @volumes << volume
        end

        def default_iso_dir
          "/var/lib/libvirt/images"
        end

        def default_volume_name
          "#{name}.#{volume_format_type || 'img'}"
        end

        def defaults
          {
            :persistent             => true,
            :cpus                   => 1,
            :memory_size            => 256 *1024,
            :name                   => randomized_name,
            :os_type                => "hvm",
            :arch                   => "x86_64",
            :domain_type            => "kvm",
            :iso_dir                => default_iso_dir,
            :network_interface_type => "network",
            :network_nat_network    => "default",
            :network_bridge_name    => "br0",
            :boot_order             => %w[hd cdrom network],
            :display                => default_display
          }
        end

        def verify_boot_order order = []
          valid_boot_media = %w[cdrom fd hd network]
          if order
            order.each do |b|
              raise "invalid boot order, possible values are any combination of: #{valid_boot_media.join(', ')}" unless valid_boot_media.include?(b)
            end
          end
        end

        def default_display
          {:port => '-1', :listen => '127.0.0.1', :type => 'vnc', :password => '' }
        end
      end
    end
  end
end
