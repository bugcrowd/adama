module Adama
  # Extend class with module methods
  #
  # class CollectUnderpantsCommand
  #   include Adama::Command
  #
  #   def call
  #     got_get_underpants()
  #   end
  #
  #   def rollback
  #     return_underpants_to_rightful_owner()
  #   end
  # end
  module Command
    # Internal: Install Command's behavior in the given class.
    def self.included(base)
      base.class_eval do
        include Validator
        extend ClassMethods
        attr_reader :kwargs
      end
    end

    module ClassMethods
      # public invoke a command
      def call(**kwargs)
        new(**kwargs).tap(&:run)
      end
    end

    def initialize(**kwargs)
      @kwargs = kwargs
      insert_kwarg_attributes(kwargs)
    end

    def insert_kwarg_attributes(kwargs)
      kwargs.each do |key, value|
        instance_variable_set "@#{key}", value

        self.class.class_eval do
          attr_accessor :"#{key}"
        end
      end
    end

    # Internal instance method. Called by both the call class method, and by
    # the call method in the invoker. If it fails it rolls back the command
    # and raises a CommandError.
    def run(enable_rollback: true)
      call
    rescue => error
      rollback if enable_rollback
      raise Errors::CommandError.new error: error, command: self
    end

    # Public instance method. Override this in classes this module is
    # included in.
    def call; end

    # Public instance method. Override this in classes this module is
    # included in.
    def rollback; end
  end
end
