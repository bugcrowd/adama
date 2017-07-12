require 'spec_helper'

RSpec.describe Adama::Errors::BaseError do
  describe '#to_s' do
    subject(:error_string) { described_class.new(error: error, command: command).to_s }
    before(:all) { Object.const_set('TestCommand', Class.new.send(:include, Adama::Command)) }
    let(:error) { StandardError.new('test message') }
    let(:command) { TestCommand.new }

    it 'contains the class name and message of the wrapped error' do
      expect(error_string).to match /StandardError: test message/
    end

    it 'contains the class of of the failed command' do
      expect(error_string).to match /TestCommand/
    end
  end
end
