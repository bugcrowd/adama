module Adama
  module Errors
    class BaseError < StandardError
      attr_reader :error, :command, :invoker

      def initialize(error: nil, command: nil, invoker: nil)
        @error = error
        @command = command
        @invoker = invoker
      end
    end
    class CommandError < BaseError; end
    class InvokerError < BaseError; end
    class InvokerRollbackError < BaseError; end
  end
end
