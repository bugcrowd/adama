module Adama
  module Validator
    def self.included(base)
      base.class_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def validates_presence_of(*attributes)
        validators << PresenceValidator.new(*attributes)
      end

      def validators
        @validators ||= []
      end
    end

    module InstanceMethods
      def errors
        @errors ||= {}
      end

      def valid?
        @valid
      end

      def validate!
        @valid = true
        self.class.validators.each do |validator|
          validator.validate! self
          merge_errors validator.errors
          @valid = validator.valid? && @valid
        end
      end

      private

      def merge_errors(new_errors)
        errors.merge!(new_errors) do |key, oldval, newval|
          (newval.is_a?(Array) ? (oldval + newval) : (oldval << newval)).uniq
        end
      end
    end

    class PresenceValidator
      attr_accessor :errors

      def initialize(*attributes)
        @attributes = attributes.flatten
        @errors = {}
      end

      def valid?
        @valid
      end

      def validate!(instance)
        @valid = true
        @attributes.each do |attribute|
          @valid = attr_accessor_exists?(instance, attribute) && @valid
        end
      end

      def attr_accessor_exists?(instance, attribute)
        exists = instance.respond_to?(attribute) &&
          instance.respond_to?("#{attribute}=".to_sym)
        @errors[attribute] = ['attribute missing'] unless exists
        exists
      end
    end
  end
end
