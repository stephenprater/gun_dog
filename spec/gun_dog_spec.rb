require "spec_helper"

RSpec.describe GunDog do
  it "has a version number" do
    expect(GunDog::VERSION).not_to be nil
  end

  describe '.trace' do
    it 'generates call record objects with method call stats' do
      trace = GunDog.trace(Tester) do
        Tester.new.foo('a thing')
      end

      aggregate_failures do
        expect(trace.find_call_record('Tester#foo')[0]).to be_an_instance_of(GunDog::CallRecord)
        expect(trace.method_list).to eq(['Tester#foo'])
        expect(trace.find_call_record('Tester#foo').count).to eq 1
        expect(trace.find_call_record('Tester#foo')[0].args).to eq(:arg => String)
        expect(trace.find_call_record('Tester#foo')[0].return_value).to eq String
      end
    end

    it 'generates duck type signatures for call records' do
      trace = GunDog.trace(Tester) do
        Tester.new.foo_ducks
      end

      expect(trace.find_call_record('Tester#foo').map(&:to_s)).to contain_exactly(
        'def foo(arg : String) => String',
        'def foo(arg : TrueClass) => String',
        'def foo(arg : Array) => String'
      )
    end

    it 'return value is accurate over nested calls' do
      trace = GunDog.trace(Tester) do
        Tester.new.baz
      end

      aggregate_failures do
        expect(trace.find_call_record('Tester#bar')[0].return_value).to eq String
        expect(trace.find_call_record('Tester#baz')[0].return_value).to eq String
      end
    end

    it 'marks methods called only from within the object as `internal`' do
      trace = GunDog.trace(Tester) do
        Tester.new.baz
      end

      # bar is called only by baz and not by any external collaborator

      aggregate_failures do
        expect(trace.find_call_record('Tester#bar')[0].internal?).to be true
        expect(trace.find_call_record('Tester#baz')[0].internal?).to be false
      end
    end

    it 'marks methods called "ourobourous style" as `cyclical`' do
      trace = GunDog.trace(Tester) do
        Tester.new.cyclical_boo_bar
      end

      # bar is called by a collaborating_class but the entire call stack
      # originated in the Tester class
      #
      # we don't make an attempt to keep track of where the cycle is here

      aggregate_failures do
        expect(trace.find_call_record('Tester#bar')[0].cyclical?).to be true
        expect(trace.find_call_record('Tester#bar')[0].internal?).to be false
      end
    end

    it 'when a call to a collaborating class originates from inside the traced class' do
      trace = GunDog.trace(Tester) do
        Tester.new.cyclical_boo_bar
      end

      expect(trace.collaborating_classes).to include CollaboratingTester
    end

    it 'when a call to a collaborating class originates from outside the traced class' do
      trace = GunDog.trace(Tester) do
        CollaboratingTester.new.foo
      end

      aggregate_failures do
        expect(trace.collaborating_classes).to_not include CollaboratingTester
      end
    end

    it 'locates calls to class methods differently' do
      trace = GunDog.trace(Tester) do
        Tester.test
      end

      expect(trace.find_call_record('Tester.test').count).to eq 1
    end

    it 'records return values for class methods' do
      trace = GunDog.trace(Tester) do
        Tester.test
      end

      expect(trace.find_call_record('Tester#poop!')[0].return_value).to eq Tester::Poop
      expect(trace.find_call_record('Tester#poop!')[0].return_value).to eq Tester::Poop
      expect(trace.collaborating_classes).to include Tester::Poop
      expect(trace.collaborating_classes).to include CollaboratingTester
      expect(trace.collaborating_classes).to include Tester::AbstractFactory
    end

    context 'when an exception is raised' do
      it 'reraises the exception' do
        expect {
          GunDog.trace(Tester) do
            Tester.new.method_interrupted
          end
        }.to raise_error(RuntimeError).with_message('ow!')
      end
    end

    context 'a big ol integration test' do
      it 'includes call records for the traced class' do
        trace = GunDog.trace(Tester) do
          Tester.test
        end

        # require 'pry'; binding.pry

        # this is a good place to put a pry and explore the output
      end
    end
  end
end
