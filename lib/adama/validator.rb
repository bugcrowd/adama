module Adama
  module Validator
    def self.prepended(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def validates_presence_of(*attributes)
        # Assign the validator if it exists, ortherwise create a new one and
        # append it to the validators array
        unless validator = validators.find { |v| v.is_a? PresenceValidator }
          validator = PresenceValidator.new
          validators << validator
        end

        # Append the passed in attributes. This will result in a list
        # of unique attributes.
        validator.merge_new_attributes(*attributes)
      end

      # Maintain an array of validators
      def validators
        @validators ||= []
      end
    end

    # This module is meant to be prepended to another module
    # Call the child class initializer first, this will set kwargs
    # Then validate
    def initialize(kwargs)
      super(kwargs)
      validate!
    end

    def errors
      @errors ||= {}
    end

    def valid?
      @valid
    end

    # Iterate over the validators registered, and for each validator
    # call `validate!` passing in the instance of the class this module
    # was prepended to.
    def validate!
      @valid = true
      self.class.validators.each do |validator|
        validator.validate! self
        merge_errors validator.errors
        @valid = validator.valid? && @valid
      end
    end

    private

    # Create a uniform error output, per attribute
    def merge_errors(new_errors)
      errors.merge!(new_errors) do |key, oldval, newval|
        (newval.is_a?(Array) ? (oldval + newval) : (oldval << newval)).uniq
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

      def merge_new_attributes(*attributes)
        @attributes |= attributes
      end

      def validate!(instance)
        @valid = true
        kwargs = instance.kwargs
        @attributes.each do |attribute|
          present = kwargs.include? attribute
          if present
            set_instance_variable instance, attribute, kwargs[attribute]
          else
            @errors[attribute] = ['attribute missing']
          end
          @valid = present && @valid
        end
      end

      def set_instance_variable(instance, key, value)
        instance.instance_variable_set "@#{key}", value
        instance.class.class_eval { attr_accessor :"#{key}" }
      end
    end
  end
end
