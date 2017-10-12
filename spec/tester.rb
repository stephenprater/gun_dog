class Tester
  class Poop
    def smell?
      true
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
