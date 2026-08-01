require "fog/core/model"
require "nokogiri"

require_relative "../../common/attribute_model"
require_relative "../driver/statistics"
require_relative "../driver/virtio"
require_relative "../driver/iothread"
require_relative "metadata_cache"

module Fog
  module Libvirt
    class Compute
      class Server < Fog::Compute::Server
        class Disk < AttributeModel
          class Driver < AttributeModel
            include Fog::Libvirt::Util

            attribute :name
            attribute :type
            attribute :cache
            attribute :error_policy
            attribute :rerror_policy
            attribute :io
            attribute :ioeventfd
            attribute :event_idx
            attribute :copy_on_read
            attribute :discard
            attribute :detect_zeroes
            attribute :iothread
            attribute :queues
            attribute :queue_size
            attribute :discard_no_unref

            include Server::Driver::Virtio

            attribute :iothreads, :type => Array
            attribute :statistics
            attribute :metadata_cache

            autocast_on_assign :iothreads, [Server::Driver::IOThread]
            autocast_on_assign :statistics, Server::Driver::Statistics
            autocast_on_assign :metadata_cache, MetadataCache

            def self.parse_xml(node)
              return nil unless node

              attrs = xml_attrs(node, :autocast_int => true)

              attrs[:iothreads] = node.xpath("iothreads/iothread").map { |iothread_node| Server::Driver::IOThread.parse_xml(iothread_node) }
              attrs.delete(:iothreads) if attrs[:iothreads].empty?

              attrs[:statistics] = Server::Driver::Statistics.parse_xml(node.at_xpath("statistics"))
              attrs[:metadata_cache] = MetadataCache.parse_xml(node.at_xpath("metadata_cache"))

              attrs.compact
            end

            def build_xml(xml)
              xml.driver(attrs_xml(attributes.except(:iothreads, :statistics, :metadata_cache).compact, :casing => :snake, :switch => true)) do
                unless iothreads.empty?
                  xml.iothreads do
                    iothreads.each { |iothread| model_cast(iothread, Server::Driver::IOThread).build_xml(xml) }
                  end
                end
                statistics&.build_xml(xml)
                metadata_cache&.build_xml(xml)
              end
            end
          end
        end
      end
    end
  end
end
