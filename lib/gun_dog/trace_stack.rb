module GunDog
  class TraceStack < Array
    attr_reader :collaborating_classes, :klass

    def self.from_json(json)
      ts = new(json['klass'])

      ts.instance_eval do
        @collaborating_classes = Set.new(json['collaborating_classes'].map { |k| Kernel.const_get(k) })
      end

      ts
    end

    def classes_in_stack
      self.group_by(&:klass).keys.to_set
    end

    def initialize(klass)
      @klass = klass
      @collaborating_classes = Set.new
    end

    def internal_stack?
      # if the set of the classes contained in the trace is equivalent to the
      # set of our own class then it is an interal stack (ie - all methods are
      # internal to the traced class)
      call_stack.classes_in_stack == self_set
    end

    def cyclical_stack?
      # if the set of classes contained in the trace is a superset of the set
      # of our class then it is a cyclical stack (ie, it contains calls both
      # within and without of the class)
      call_stack.classes_in_stack > self_set
    end

    def preceded_by_traced_klass?
      traced_klasses = self.map(&:klass)
      traced_klasses.include?(klass) || traced_klasses.include?(klass.singleton_class)
    end

    def self_set
      [klass].to_set
    end

    def call_stack
      # the stack excluding the sentinel (element zero) and our selves (element -1)
      self.slice(1 .. -2) || TraceStack.new(klass)
    end

    def <<(frame)
      collaborating_classes.add(frame.klass) if preceded_by_traced_klass?
      super(frame)
    end
  end
end
