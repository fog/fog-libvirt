require 'nokogiri'
require 'securerandom'

module Fog
  module Libvirt
    module Util
      def xml_element(xml, path, attribute=nil)
        xml = Nokogiri::XML(xml)
        attribute.nil? ? (xml/path).first.text : (xml/path).first[attribute.to_sym]
      end

      def xml_elements(xml, path, attribute=nil)
        xml = Nokogiri::XML(xml)
        attribute.nil? ? (xml/path).map : (xml/path).map{|element| element[attribute.to_sym]}
      end

      def randomized_name
        "fog-#{(SecureRandom.random_number*10E14).to_i.round}"
      end

      module ClassMethods
        def xml_attrs(node, autocast_int: false)
          return {} unless node

          attrs = node.to_h.transform_keys { |name| xml_underscore(name).to_sym }
          attrs.transform_values! { |value| xml_value(value, :autocast_int => autocast_int) }
          attrs
        end

        # Copied from fog-core/lib/fog/core/provider.rb
        def xml_underscore(name)
          name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
        end

        def xml_value(value, autocast_int: false)
          return nil if value.nil?
          return ["yes", "on"].include?(value) if ["yes", "no", "on", "off"].include?(value)

          return value.to_i if autocast_int && value.match?(/^-?(0|[1-9]\d*)$/)

          value
        end

        def autocast_on_assign(name, type)
          assign_name = "#{name}=".to_sym
          remove_method(assign_name) if method_defined?(assign_name)
          if type.is_a?(Array)
            type = type.first
            raise "Missing type for Array" if type.nil?

            create_array_assigner(assign_name, name, type)
          else
            define_method(assign_name) do |value|
              attributes[name] = value.nil? || value.is_a?(type) ? value : type.new(value)
            end
          end
        end

        def model_cast(value, type)
          return value if value.is_a?(type)

          type.new(value)
        end

        def models_cast(models, type)
          models.map { |model| model_cast(model, type) }
        end

        private

        def create_array_assigner(assign_name, attr_name, type)
          define_method(assign_name) do |values|
            attributes[attr_name] = if values.nil?
                                      []
                                    elsif !values.is_a?(Array)
                                      [values.is_a?(type) ? values : type.new(values)]
                                    else
                                      values.map { |value| value.is_a?(type) ? value : type.new(value) }
                                    end
          end
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def attrs_xml(attrs, casing: :camel, switch: false)
        attrs = attrs.to_h
        attrs.transform_keys! { |name| attr_camelcase(name).to_sym } if casing == :camel
        attrs.transform_values! { |value| value_xml(value, :switch => switch) }
        attrs
      end

      def attr_camelcase(name)
        first, *rest = name.to_s.split("_")
        return name if rest.empty?

        first + rest.map(&:capitalize).join
      end

      def value_xml(value, switch: false)
        return nil if value.nil?

        if [true, false].include?(value)
          return value ? "on" : "off" if switch

          return value ? "yes" : "no"
        end

        value
      end

      def model_cast(value, type)
        self.class.model_cast(value, type)
      end

      def models_cast(models, type)
        self.class.models_cast(models, type)
      end
    end
  end
end
