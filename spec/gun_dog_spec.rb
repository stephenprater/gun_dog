require "spec_helper"

RSpec.describe GunDog do
  it "has a version number" do
    expect(GunDog::VERSION).not_to be nil
  end

  before(:each) do
    GunDog.configure do |c|
      c.suppress_methods = {
        ActiveRecord::Base => [
          'self.default_scope_override',
          'supressed!',
          'self.__callbacks',
          'self._reflections',
        ]
      }
    end
  end

  describe '.trace' do
    it 'generates call record objects with method call stats' do
      trace = GunDog.trace(Tester) { Tester.new.foo('a thing') }.explore

      aggregate_failures do
        expect(trace['Tester#foo'][0]).to be_an_instance_of(GunDog::CallRecord)
        expect(trace.methods).to eq(['Tester#foo'])
        expect(trace['Tester#foo'].count).to eq 1
        expect(trace['Tester#foo'][0].args).to eq(:arg => 'a thing')
        expect(trace['Tester#foo'][0].return_value).to eq 'foo'
      end
    end

    it 'generates duck type signatures for call records' do
      trace = GunDog.trace(Tester) { Tester.new.foo_ducks }.explore

      expect(trace.unique_call_signatures).to contain_exactly(
        'def foo(arg : String) : String (internal)',
        'def foo(arg : TrueClass) : String (internal)',
        'def foo(arg : Array) : String (internal)',
        'def foo_ducks() : String'
      )
    end

    it 'return value is accurate over nested calls' do
      trace = GunDog.trace(Tester) { Tester.new.baz }.explore

      aggregate_failures do
        expect(trace['Tester#bar'][0].return_value).to eq "bar"
        expect(trace['Tester#baz'][0].return_value).to eq "bar"
      end
    end

    it 'marks methods called only from within the object as `internal`' do
      trace = GunDog.trace(Tester) { Tester.new.baz }.explore

      # bar is called only by baz and not by any external collaborator

      aggregate_failures do
        expect(trace['Tester#bar'][0].internal?).to be true
        expect(trace['Tester#baz'][0].internal?).to be false
      end
    end

    it 'marks methods called "ourobourous style" as `cyclical`' do
      trace = GunDog.trace(Tester) { Tester.new.cyclical_boo_bar }.explore

      # bar is called by a collaborating_class but the entire call stack
      # originated in the Tester class
      #
      # we don't make an attempt to keep track of where the cycle is here

      aggregate_failures do
        expect(trace['Tester#bar'][0].cyclical?).to be true
        expect(trace['Tester#bar'][0].internal?).to be false
      end
    end

    it 'when a call to a collaborating class originates from inside the traced class' do
      trace = GunDog.trace(Tester) { Tester.new.cyclical_boo_bar }.explore

      expect(trace.collaborating_classes).to include CollaboratingTester
    end

    it 'when a call to a collaborating class originates from outside the traced class' do
      trace = GunDog.trace(Tester) { CollaboratingTester.new.foo }.explore

      aggregate_failures do
        expect(trace.collaborating_classes).to_not include CollaboratingTester
      end
    end

    it 'tracks weird bullshit like AR attribute methods correctly', :database do
      Tester::TestRecord.new

      trace = GunDog.trace(Tester::TestRecord) { Tester.new.get_some_ar_foo }.explore

      aggregate_failures do
        expect(trace.unique_call_signatures).to include(
          "[generated] def foo() : Fixnum",
          "[generated] def foo=(value : Fixnum) : Fixnum",
          "[generated] def bar() : String",
          "[generated] def bar=(value : String) : String"
        )
      end
    end

    context 'tracking AR relationship methods', :database do
      before do
        other_tester = Tester::OtherTester.create(bacon: 'smelly')
        Tester::TestRecord.create(foo: 1, other_testers: [other_tester])
      end

      it 'works on has many' do
        trace = GunDog.trace(Tester::TestRecord) { Tester::TestRecord.first.other_testers.first }.explore
        expect(trace.unique_call_signatures).to include("[generated] def other_testers(args : Array) : Tester::OtherTester::ActiveRecord_Associations_CollectionProxy")
      end

      it 'works on belongs to' do
        trace = GunDog.trace(Tester::OtherTester) { Tester::OtherTester.first.test_record }.explore
        expect(trace.unique_call_signatures).to include("[generated] def test_record(args : Array) : Tester::TestRecord")
      end
    end

    it 'tracks AR singleton methods that are defined directy in your class', :database do
      Tester::TestRecord.create(foo: 1)
      Tester::TestRecord.recordable_scope

      trace = GunDog.trace(Tester::TestRecord) { Tester::TestRecord.recordable_scope }.explore

      aggregate_failures do
        expect(trace.unique_call_signatures).to include(
          "def self.recordable_scope(args : Array) : Tester::TestRecord::ActiveRecord_Relation"
        )
      end
    end

    it 'supresses methods on the supression list', :database do
      pending
      Tester::TestRecord.default_scope_override

      trace = GunDog.trace(Tester::TestRecord) { Tester::TestRecord.new.some_stuff}.explore

      aggregate_failures do
        expect(trace.unique_call_signatures).to include(
          "def some_stuff() : Array",
          "def self.recordable_scope() : Tester::TestRecord::ActiveRecord_Relation"
        )
      end
    end

    it 'can successfully log missing methods as their called name' do
      trace = GunDog.trace(Tester) { Tester.new.floobert }.explore

      aggregate_failures do
        expect(trace.unique_call_signatures).to contain_exactly(
          'def method_missing(name : floobert, args : [], block : NilClass) : TrueClass',
          'def floobert_was_missing() : TrueClass (internal) (dynamic)'
        )
      end
    end

    it 'locates calls to class methods differently' do
      trace = GunDog.trace(Tester) { Tester.eigen_method }.explore

      expect(trace['Tester.eigen_method'].count).to eq 1
    end

    it 'records return values for class methods', :database do
      trace = GunDog.trace(Tester) { Tester.test }.explore

      expect(trace['Tester#poop!'][0].return_value).to be_an_instance_of Tester::Poop
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

    context 'a big ol integration test', :database do
      it 'includes call records for the traced class' do
        trace = GunDog.trace(Tester) { Tester.test }.explore

        # require 'pry'; binding.pry

        # this is a good place to put a pry and explore the output
      end
    end
  end
end
