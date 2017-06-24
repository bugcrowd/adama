shared_examples :command_base do
  let(:command) { Class.new.send(:include, described_class) }

  describe '.new' do
    let(:instance) { command.new(foo: 'bar') }

    it { expect(instance).to be_a(command) }
  end

  describe '.call' do
    let(:instance) { instance_double(command) }
    subject        { command.call(foo: 'bar') }

    before do
      allow(command).to receive(:new).and_return(instance)
      allow(instance).to receive(:run)
      subject
    end

    it { expect(command).to have_received(:new).once.with(foo: 'bar') }
    it { expect(instance).to have_received(:run).once.with(no_args) }
  end

  describe '#run' do
    let(:instance) { command.new }
    subject        { instance.run }

    context 'when the call is successful' do
      before do
        allow(instance).to receive(:run).once.with(no_args)
        subject
      end

      it { expect(instance).to have_received(:run).once.with(no_args) }
    end

    context 'when the call raises an error' do
      before do
        allow(instance).to receive(:call).and_raise(StandardError)
        allow(instance).to receive(:rollback)
      end

      it 'raises the error, then calls rollback' do
        expect { instance.run }.to raise_error(Adama::Errors::BaseError) do |_error|
          expect(instance).to have_received(:rollback).once.with(no_args)
        end
      end
    end
  end
end
