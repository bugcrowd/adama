module Adama
  # Invoker lets you run many commands in sequence, and roll them back
  # in reverse order.
  #
  # class SuccessfulBusinessCreator
  #   include Adama::Invoker
  #
  #   invoke(
  #     CollectUnderpantsCommand,
  #     MagicHappensCommand,
  #     ProfitCommand,
  #   )
  # end
  #
  # SuccessfulBusinessCreator.call(min_underpants: 100)
  #
  module Invoker
    # Internal: Install Command's behavior in the given class.
    def self.included(base)
      base.class_eval do
        # We inherit the Command module's call methods
        include Command

        # Our new class methods enable us to set the command list
        extend ClassMethods

        # We override the Command class instance methods:
        #
        #   run
        #   call
        #   rollback
        include InstanceMethods
      end
    end

    # Our new class methods enable us to set the command list
    module ClassMethods

      # Public class method. Call invoke in your class definition to
      # specify which commands will be executed.
      #
      # class SuccessfulBusinessCreator
      #   include Adama::Invoker
      #
      #   invoke(
      #     CollectUnderpantsCommand,
      #     MagicHappensCommand,
      #     ProfitCommand,
      #   )
      # end
      def invoke(*command_list)
        @commands = command_list.flatten
      end

      # internal class method. So we can loop through the commands that
      # have been assigned by the including class.
      def commands
        @commands ||= []
      end
    end

    module InstanceMethods
      # Internal instance method. Called by the included Command module's .call
      # class method. We've overridden command's instance method because we
      # don't want it to have optional rollback.
      #
      # Always raises Errors::InvokerError and has the #invoker and #error
      # attribute set. In the case where the error is raised within the
      # invoker "call" instance method, we won't have access to error's
      # command so need to test for it's existence.
      def run
        call
      rescue => error
        rollback
        raise Errors::InvokerError.new(
          error: error,
          command: error.respond_to?(:command) ? error.command : nil,
          invoker: self
        )
      end

      # Maintain an array of commands that have been called.
      def _called
        @called ||= []
      end

      # To unwind the invoker, we rollback the _called array in reverse order.
      #
      # If anything fails in the command's rollback method we should raise
      # and drop out of the process as we'll need to manually remove something.
      def rollback
        _called.reverse_each do |command|
          begin
            command.rollback
          rescue => error
            raise Errors::InvokerRollbackError.new(error: error, command: command, invoker: self)
          end
        end
      end

      # Iterate over the commands array, instantiate each command, add it to
      # the called list and then run it. We don't want the command to call
      # rollback itself as that will be handled by the rollback method above.
      # To ensure this doesn't happen we pass in enable_rollback: false.
      # Please ensure the command is placed on the array _prior_ to calling
      # run, or else we'll miss rolling back the command that failed.
      def call
        self.class.commands.each do |command_klass|
          command = command_klass.new(kwargs)
          _called << command
          command.run(enable_rollback: false)
        end
      end
    end
  end
end
