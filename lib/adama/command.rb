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
        extend ClassMethods
        attr_reader :kwargs
      end
    end

    module ClassMethods
      # public invoke a command
      def call(kwargs = {})
        new(kwargs).tap(&:run)
      end
    end

    def initialize(kwargs = {})
      @kwargs = kwargs
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
