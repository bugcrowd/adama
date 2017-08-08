shared_examples :command_base do
  context 'command examples' do
    let(:klass)    { Class.new.send(:include, described_class) }
    let(:kwargs)   { {} }
    let(:instance) { klass.new kwargs}

    describe '.new' do
      it { expect(instance).to be_a(klass) }
    end

    describe '.call with kwargs' do
      let(:kwargs) { { foo: 'bar', key: 'val' } }

      before do
        allow(klass).to receive(:new).and_return(instance)
        allow(instance).to receive(:run)
        klass.call(kwargs)
      end

      it { expect(klass).to have_received(:new).once.with(kwargs) }
      it { expect(instance).to have_received(:run).once.with(no_args) }
    end

    describe '.call without args' do
      before do
        allow(klass).to receive(:new).and_return(instance)
        allow(instance).to receive(:run)
        klass.call
      end

      it { expect(klass).to have_received(:new).once.with({}) }
      it { expect(instance).to have_received(:run).once.with(no_args) }
    end

    describe '#run' do
      context 'when the call is successful' do
        before do
          allow(instance).to receive(:run).once.with(no_args)
          instance.run
        end

        it { expect(instance).to have_received(:run).once.with(no_args) }
      end

      context 'when the call raises an error' do
        before do
          allow(instance).to receive(:call).and_raise(StandardError)
        end

        it 'raises the error' do
          expect { instance.run }.to raise_error(Adama::Errors::BaseError)
        end
      end
    end
  end
end
