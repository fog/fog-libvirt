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

      def self.hash_except(hash, *attrs)
        hash.respond_to?(:except) ? hash.except(*attrs) : hash.reject { |key, _| attrs.include?(key) }
      end

      def hash_except(*attrs)
        Util.hash_except(*attrs)
      end

      module ClassMethods
        def xml_value(value)
          return nil if value.nil?
          return ["yes", "on"].include?(value) if ["yes", "no", "on", "off"].include?(value)

          value
        end

        # Copied from fog-core/lib/fog/core/provider.rb
        def xml_underscore(name)
          name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .tr("-", "_")
              .downcase
        end

        def xml_attrs(node)
          return {} unless node

          attrs = node.to_h.transform_keys { |name| xml_underscore(name).to_sym }
          attrs.transform_values! { |value| xml_value(value) }
          attrs
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

      def attr_camelcase(name)
        first, *rest = name.to_s.split("_")
        return name if rest.empty?

        first + rest.map(&:capitalize).join
      end

      def value_xml(value)
        return nil if value.nil?
        return value ? "yes" : "no" if [true, false].include?(value)

        value
      end

      def xml_switch(value)
        return nil if value.nil?

        value ? "on" : "off"
      end

      def xml_underscore(attrs)
        self.class.xml_underscore(attrs)
      end

      def attrs_underscore(attrs)
        attrs.to_h.transform_keys { |name| xml_underscore(name.to_s).to_sym }
      end

      def attrs_xml(attrs)
        attrs = attrs.to_h.transform_keys { |name| attr_camelcase(name).to_sym }
        attrs.transform_values! { |value| value_xml(value) }
        attrs
      end

      def normalize_ip_range(range)
        end_val = range.end.to_s
        if range.exclude_end?
          last_ip = IPAddr.new(end_val)
          end_val = IPAddr.new(last_ip.to_i - 1, last_ip.family).to_s
        end
        { :start => range.begin.to_s, :end => end_val }
      end

      def normalize_number_range(range)
        end_val = range.end.to_i
        end_val -= 1 if range.exclude_end?
        { :start => range.begin.to_i, :end => end_val }
      end

      def model_cast(value, type)
        self.class.model_cast(value, type)
      end

      def models_cast(models, type)
        self.class.models_cast(models, type)
      end

      def model_empty?(model)
        return true if model.nil?

        if model.respond_to?(:attributes)
          model.attributes.values.all? { |value| model_empty?(value) }
        elsif model.respond_to?(:empty?)
          model.empty?
        else
          false
        end
      end

      def models_equal?(left, right)
        return true if left.nil? && model_empty?(right)
        return true if right.nil? && model_empty?(left)
        return false unless left.instance_of?(right.class)

        if left.is_a?(Array)
          model_arrays_equal?(left, right)
        elsif left.is_a?(Hash)
          model_hashes_equal?(left, right)
        elsif left.respond_to?(:attributes)
          models_equal?(left.attributes, right.attributes)
        else
          left == right
        end
      end

      private

      def model_arrays_equal?(left, right)
        left.length == right.length && left.zip(right).all? { |x, y| models_equal?(x, y) }
      end

      def model_hashes_equal?(left, right)
        left.length == right.length && left.all? { |key, value| right.key?(key) && models_equal?(value, right[key]) }
      end
    end
  end
end
