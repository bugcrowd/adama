require 'spec_helper'
require_relative 'validator_examples'
require_relative 'command_examples'

RSpec.describe Adama::Invoker do
  # Run normal command spec examples for
  # invokers because an Invoker is a glorified
  # version of a command.
  include_examples :validator_base
  include_examples :command_base

  # Configure for Invoker #invoke tests
  before(:context) do
    Object.const_set('Invoker', Class.new.send(:include, Adama::Invoker))
    Object.const_set('Command1', Class.new.send(:include, Adama::Command))
    Object.const_set('Command2', Class.new.send(:include, Adama::Command))
    Object.const_set('Command3', Class.new.send(:include, Adama::Command))
    Object.const_set('Command4', Class.new.send(:include, Adama::Command))
  end

  let(:instance_1) { Command1.new }
  let(:instance_2) { Command2.new }
  let(:instance_3) { Command3.new }
  let(:instance_4) { Command4.new }

  let(:command_list) { [Command1, Command2, Command3, Command4] }
  let(:kwargs)       { { foo: 'bar' } }

  # Mock the new method on the commands to return our defined
  # instances.
  before do
    allow(Command1).to receive(:new).and_return(instance_1)
    allow(Command2).to receive(:new).and_return(instance_2)
    allow(Command3).to receive(:new).and_return(instance_3)
    allow(Command4).to receive(:new).and_return(instance_4)
  end

  describe '.call' do
    before do
      allow(instance_1).to receive(:run)
      allow(instance_2).to receive(:run)
      allow(instance_3).to receive(:run)
      allow(instance_4).to receive(:run)

      invokable.invoke(*command_list)
      invoke
    end

    shared_examples 'calls the commands in order' do
      it 'calls .new on the commands in order' do
        expect(Command1).to have_received(:new).ordered
        expect(Command2).to have_received(:new).ordered
        expect(Command3).to have_received(:new).ordered
        expect(Command4).to have_received(:new).ordered
      end

      it 'calls .call on the commands in order' do
        expect(instance_1).to have_received(:run).ordered
        expect(instance_2).to have_received(:run).ordered
        expect(instance_3).to have_received(:run).ordered
        expect(instance_4).to have_received(:run).ordered
      end
    end

    # There are two methods of passing an Invoker a list
    # of commands to run.
    #
    # The first methods sets up the command list in the class
    # definition, which stores the array of commands as a
    # class member var. This means that every Invoker of that
    # type calls the same comnmands.
    #
    # The second method is to initialize a new instanvce of
    # an invoker and pass the list of commands to invoke
    # to the instance. This means that we can dynamically
    # change the command list per Invoker instance.

    context 'When an Invoker class is passed a command list' do
      # The first method:
      #
      #   class Invoker
      #     include Adama::Invoker
      #     invoke(Command1, Command2)
      #   end
      #
      #   Invoker.call(foo: bar)
      #
      let(:invokable) { Invoker }
      let(:invoke) { invokable.call **kwargs }

      it_behaves_like 'calls the commands in order'
    end

    context 'When an Invoker instance is passed a command list' do
      # The second method:
      #
      #   class Invoker
      #     include Adama::Invoker
      #   end
      #
      #   Invoker.new(foo: bar).invoke(Command1, Command2).run
      #
      #
      # NOTE: WE CALL `#run` ON THE INSTANCE INSTEAD OF `#call`
      #
      # This is because the `#run` method is the main executor
      # in the context of the instance, and is wrapped in the
      # internall error handlers.
      #
      let(:invokable) { Invoker.new **kwargs }
      let(:invoke) { invokable.run }

      it_behaves_like 'calls the commands in order'
    end
  end

  describe 'rollback' do
    before do
      ########################
      ## Instance level mocks

      # Ensure the first three calls succeed.
      #
      # We fail the fourth call below.
      #
      # This will allow us to test the forward
      # run and the reverse rollback.
      allow(instance_1).to receive(:call)
      allow(instance_2).to receive(:call)
      allow(instance_3).to receive(:call)

      # Allow each specific command instance to receive rollback.
      allow(instance_1).to receive(:rollback)
      allow(instance_2).to receive(:rollback)
      allow(instance_3).to receive(:rollback)

      allow_any_instance_of(Invoker).to receive(:rollback).and_call_original

      invokable.invoke(*command_list)
    end

    context 'fourth command call fails' do
      before do
        # Fail the fourth call
        allow(instance_4).to receive(:call).and_raise(StandardError)
        allow(instance_4).to receive(:rollback)
      end

      shared_examples 'rolls back in the correct order' do
        it 'calls #rollback in reverse order on the commands that succeeded' do
          expect { invoke }
            .to raise_error(Adama::Errors::InvokerError) do |error|
            expect(error.invoker).to be_a(Invoker)
            expect(error.command).to be_a(Command4)
            expect(error.error).to be_a(StandardError)

            expect(instance_1).to have_received(:call).with(no_args).ordered
            expect(instance_2).to have_received(:call).with(no_args).ordered
            expect(instance_3).to have_received(:call).with(no_args).ordered
            expect(instance_4).to have_received(:call).with(no_args).ordered

            expect(instance_3).to have_received(:rollback).with(no_args).ordered
            expect(instance_2).to have_received(:rollback).with(no_args).ordered
            expect(instance_1).to have_received(:rollback).with(no_args).ordered

            expect(instance_4).not_to have_received(:rollback).with(no_args)
          end
        end
      end

      context 'When an Invoker class is passed a command list' do
        let(:invokable) { Invoker }
        let(:invoke) { invokable.call **kwargs }

        it_behaves_like 'rolls back in the correct order'
      end

      context 'When an Invoker instance is passed a command list' do
        let(:invokable) { Invoker.new **kwargs }
        let(:invoke) { invokable.run }

        it_behaves_like 'rolls back in the correct order'
      end
    end

    context 'fourth command rollback fails' do
      before do
        allow(instance_4).to receive(:call)
        allow(instance_4).to receive(:rollback).and_raise(StandardError)
      end

      shared_examples 'fails in the correct manner' do
        it 'failed #rollback raises catastrophic rollback error' do
          expect { invoke.rollback }
            .to raise_error(Adama::Errors::InvokerRollbackError) do |error|
            expect(error.invoker).to be_a(Invoker)
            expect(error.command).to be_a(Command4)
            expect(error.error).to be_a(StandardError)

            expect(instance_1).to have_received(:call).with(no_args).ordered
            expect(instance_2).to have_received(:call).with(no_args).ordered
            expect(instance_3).to have_received(:call).with(no_args).ordered
            expect(instance_4).to have_received(:call).with(no_args).ordered

            expect(instance_4).to have_received(:rollback)
            expect(instance_3).not_to have_received(:rollback)
            expect(instance_2).not_to have_received(:rollback)
            expect(instance_1).not_to have_received(:rollback)
          end
        end
      end

      context 'When an Invoker class is passed a command list' do
        let(:invokable) { Invoker }
        let(:invoke) { invokable.call **kwargs }

        it_behaves_like 'fails in the correct manner'
      end

      context 'When an Invoker instance is passed a command list' do
        let(:invokable) { Invoker.new **kwargs }
        let(:invoke) { invokable.run }

        it_behaves_like 'fails in the correct manner'
      end
    end
  end
end
