module GunDog
  class TraceStack < Array
    attr_reader :collaborating_classes, :klass

    def self.from_json(json)
      ts = new(json['klass'])

      ts.instance_eval do
        @collaborating_classes = Set.new(json['collaborating_classes'].map { |k| Utilities.get_class(k) })
      end

      ts
    end

    def self.from_array(klass:, stack: )
      ts = new(klass)
      stack.each do |f|
        ts << GunDog::MethodOwnerStackFrame.new(Utilities.get_class(f['klass']), f['method_name'])
      end

      ts
    end

    def classes_in_stack
      self.group_by(&:klass).keys.to_set
    end

    def initialize(klass)
      @klass = klass
      @traced_klass_entry_points = Array.new
      @collaborating_classes = Set.new
    end

    def internal_stack?
      # if the set of classes contained in the trace since we entered our own
      # class is equivalent to the set of our own class then it is an internal
      # trace
      since_first_klass_entry.classes_in_stack == self_set
    end

    def cyclical_stack?
      # if the set of classes contained in the trace since we entered our own
      # class is a superset of the set of our class then it is a cyclical stack
      # (ie, it contains calls both within and without of the class)
      since_first_klass_entry.classes_in_stack > self_set
    end

    def dynamic_stack?
      methods = since_first_klass_entry.map { |f| f.method_name.to_s }
      methods.include?('method_missing') || methods.include?('send') || methods.include?('__send__')
    end

    def preceded_by_traced_klass?
      traced_klasses = self.map(&:klass)
      traced_klasses.include?(klass) || traced_klasses.include?(klass.singleton_class)
    end

    def self_set
      [klass].to_set
    end

    def since_first_klass_entry
      # the stack since the first call to a traced method excluding the current
      # frame
      self.slice((@traced_klass_entry_points.first || 1) .. -2) || GunDog::TraceStack.new(@klass)
    end

    def call_stack
      # the stack excluding the gundog sentinel (element zero) and ourselves (element -1)
      self.slice(1 .. -2) || TraceStack.new(klass)
    end

    def pop
      super.tap do |popped|
        if length == @traced_klass_entry_points.last
          @traced_klass_entry_points.pop
        end
      end
    end

    def <<(frame)
      collaborating_classes.add(frame.klass) if preceded_by_traced_klass?
      @traced_klass_entry_points << length if frame_owned_by_traced_klass?(frame)
      super(frame)
    end

    def frame_owned_by_traced_klass?(frame)
      frame.klass == klass || frame.klass.singleton_class == klass.singleton_class
    end

    def as_json
      map(&:as_json)
    end
  end
end
