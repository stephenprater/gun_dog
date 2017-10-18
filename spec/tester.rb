class Tester
  class Poop
    def smell?
      true
    end
  end

  class OtherTester < ActiveRecord::Base
    belongs_to :test_record
  end

  class TestRecord < ActiveRecord::Base
    has_many :other_testers
    scope :recordable_scope, -> { where(foo: 1) }

    def supressed!
      "this method is supressed and will not appear in call records"
    end

    def some_stuff
      self.class.recordable_scope.map(&:supressed!)
    end
  end

  class AbstractFactory
    def self.hammer
      new
    end

    def bang
      "bang!"
    end
  end

  def self.eigen_method
    new.tap do |t|
      t.bar
    end
  end

  def self.test
    new.tap do |t|
      t.foo('something')
      t.bar
      t.baz
      t.bag
      t.cyclical_boo_bar
      poop = t.poop!
      poop.smell?
      AbstractFactory.hammer.bang
    end

    TestRecord.recordable_scope
    tr = TestRecord.create(foo: 1)
    tr.foo = 2
    tr.save
    tr.foo
  end

  def method_missing(name, *args, &block)
    self.send("#{name}_was_missing")
  end

  def get_some_ar_foo
    tr = TestRecord.create(foo: 1, bar: 'bar')
    tr.foo
    tr.bar
    tr.foo = 2
    tr.bar = 'baz'
  end

  def method_interrupted
    baz
    raise "ow!"
    bar
    bag
  end

  def foo_ducks
    foo(true)
    foo("a string")
    foo([1,2,3])
  end

  def poop!
    Poop.new
  end

  def foo(arg)
    'foo'
  end

  def floobert_was_missing
    true
  end

  def bar
    # puts 'in bar'
    'bar'
  end

  def baz
    # puts 'in baz'
    bar
  end

  def bag
    'bag'
    nil
  end

  def cyclical_boo_bar
    CollaboratingTester.new.foo
  end
end

class CollaboratingTester
  def foo
    Tester.new.bar
  end
end
