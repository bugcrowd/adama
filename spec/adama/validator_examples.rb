shared_examples :validator_base do
  context 'validator examples' do
    let(:klass)    { Class.new.send(:include, described_class) }
    let(:kwargs)   { { foo: 'bar' } }
    let(:instance) { klass.new kwargs }

    describe '.validates_presence_of' do
      context 'when we validate a correctly passed in kwarg' do
        before do
          klass.send(:validates_presence_of, :foo)
          instance.validate!
        end

        it { expect(instance.valid?).to be true }
        it { expect(instance.errors).to be_empty }
      end

      context 'when we validate a correctly passed in kwarg' do
        before do
          klass.validates_presence_of :foo, :key, :jar
          klass.validates_presence_of :jar, :jar, :binks
          instance.validate!
        end

        it { expect(instance.valid?).to be false }
        it 'sets the correct errors' do
          expect(instance.errors).to eq({
            key: ['attribute missing'],
            jar: ['attribute missing'],
            binks: ['attribute missing']
          })
        end
      end
    end
  end
end
