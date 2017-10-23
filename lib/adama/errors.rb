module Adama
  module Errors
    class BaseError < StandardError
      attr_reader :error, :command, :invoker

      def initialize(error:, command:, invoker: nil, backtrace: nil)
        @error = error
        @command = command
        @invoker = invoker
        set_backtrace backtrace if backtrace
      end

      def to_s
        "#{command.class.name} failed with #{error.class}: #{error.message}"
      end
    end
    class CommandError < BaseError; end
    class InvokerError < BaseError; end
    class InvokerRollbackError < BaseError; end
  end
end
