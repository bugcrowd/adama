require 'spec_helper'
require_relative 'validator_examples'
require_relative 'command_examples'

RSpec.describe Adama::Invoker do
  include_examples :validator_base
  include_examples :command_base

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

  before do
    allow(Command1).to receive(:new).and_return(instance_1)
    allow(Command2).to receive(:new).and_return(instance_2)
    allow(Command3).to receive(:new).and_return(instance_3)
    allow(Command4).to receive(:new).and_return(instance_4)
  end

  describe '.call' do
    before do
      allow(instance_1).to receive(:run).with(enable_rollback: false)
      allow(instance_2).to receive(:run).with(enable_rollback: false)
      allow(instance_3).to receive(:run).with(enable_rollback: false)
      allow(instance_4).to receive(:run).with(enable_rollback: false)

      Invoker.invoke(*command_list)
    end

    it 'calls .new on the commands in order' do
      Invoker.call(**kwargs)
      expect(Command1).to have_received(:new).ordered
      expect(Command2).to have_received(:new).ordered
      expect(Command3).to have_received(:new).ordered
      expect(Command4).to have_received(:new).ordered

      kwargs.each do |key, value|
      end
    end

    it 'calls .call on the commands in order' do
      Invoker.call(**kwargs)
      expect(instance_1).to have_received(:run).with(enable_rollback: false).ordered
      expect(instance_2).to have_received(:run).with(enable_rollback: false).ordered
      expect(instance_3).to have_received(:run).with(enable_rollback: false).ordered
      expect(instance_4).to have_received(:run).with(enable_rollback: false).ordered
    end
  end

  describe 'rollback' do
    before do
      ########################
      ## Instance level mocks

      # Ensure the third call fails. This will allow us to test the forward
      # run and the reverse rollback.
      allow(instance_1).to receive(:call)
      allow(instance_2).to receive(:call)
      allow(instance_3).to receive(:call)

      # Allow each specific command instance to receive rollback.
      allow(instance_1).to receive(:rollback)
      allow(instance_2).to receive(:rollback)
      allow(instance_3).to receive(:rollback)

      allow_any_instance_of(Invoker).to receive(:rollback).and_call_original
    end

    context 'fourth command rollback fails' do
      before do
        allow(instance_4).to receive(:call).and_raise(StandardError)
        allow(instance_4).to receive(:rollback)
      end

      it 'calls #rollback in reverse' do
        Invoker.invoke(*command_list)
        expect { Invoker.call(**kwargs) }
          .to raise_error(Adama::Errors::InvokerError) do |error|
          expect(error.invoker).to be_a(Invoker)
          expect(error.command).to be_a(Command4)
          expect(error.error).to be_a(StandardError)

          expect(instance_1).to have_received(:call).with(no_args).ordered
          expect(instance_2).to have_received(:call).with(no_args).ordered
          expect(instance_3).to have_received(:call).with(no_args).ordered
          expect(instance_4).to have_received(:call).with(no_args).ordered

          expect(instance_4).to have_received(:rollback).with(no_args).ordered
          expect(instance_3).to have_received(:rollback).with(no_args).ordered
          expect(instance_2).to have_received(:rollback).with(no_args).ordered
          expect(instance_1).to have_received(:rollback).with(no_args).ordered
        end
      end
    end

    context 'fourth command rollback fails' do
      before do
        allow(instance_4).to receive(:call)
        allow(instance_4).to receive(:rollback).and_raise(StandardError)
      end

      it 'failed #rollback raises catastrophic rollback error' do
        Invoker.invoke(*command_list)
        invoker = Invoker.call(**kwargs)
        expect { invoker.rollback }
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
  end
end
