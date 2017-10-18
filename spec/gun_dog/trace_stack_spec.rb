require 'spec_helper'

RSpec.describe GunDog::TraceStack do
  describe 'internal_stack?' do
    let(:stack) { described_class.new(Tester) }

    before do
      stack << GunDog::MethodOwnerStackFrame.new(Array, :push)
      stack << GunDog::MethodOwnerStackFrame.new(String, :gsub)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :foo)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :bar)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :baz)
    end

    context 'when a stack slice from first tracked class call to last frame includes only our class' do
      it 'is an internal stack' do
        expect(stack.internal_stack?).to be true
      end
    end
  end

  describe 'cyclical_stack?' do
    let(:stack) { described_class.new(Tester) }

    before do
      stack << GunDog::MethodOwnerStackFrame.new(Array, :push)
      stack << GunDog::MethodOwnerStackFrame.new(String, :gsub)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :foo)
      stack << GunDog::MethodOwnerStackFrame.new(CollaboratingTester, :bar)
      stack << GunDog::MethodOwnerStackFrame.new(Array, :push)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :baz)
    end

    context 'when a stack slice from first tracked class call to last frame includes our class and others' do
      it 'is an cyclical stack' do
        expect(stack.cyclical_stack?).to be true
      end
    end
  end

  describe 'dynamic_stack?' do
    let(:stack) { described_class.new(Tester) }

    before do
      stack << GunDog::MethodOwnerStackFrame.new(Array, :push)
      stack << GunDog::MethodOwnerStackFrame.new(String, :gsub)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :foo)
      stack << GunDog::MethodOwnerStackFrame.new(CollaboratingTester, :bar)
      stack << GunDog::MethodOwnerStackFrame.new(Array, :push)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :method_missing)
      stack << GunDog::MethodOwnerStackFrame.new(Tester, :floobert_was_missing)
    end

    it 'is an meta stack' do
      expect(stack.dynamic_stack?).to be true
    end
  end
end
