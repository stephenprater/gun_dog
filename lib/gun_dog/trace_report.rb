module GunDog
  class TraceReport
    using ClassEncoding

    attr_reader :klass, :suppression_set

    def self.load(filename)
      json = MultiJson.load(File.open(filename, 'r') { |f| f.read })
      from_json(json)
    end

    def self.from_json(json)
      tr = new(nil)

      tr.instance_eval do
        @klass = Kernel.const_get(json['klass'])
        @stack = TraceStack.from_json(json.slice('klass','collaborating_classes'))
        @call_records = json['call_records'].map { |cr| CallRecord.from_json(cr) }
      end

      tr
    end

    def all_calls
      @all_calls ||= []
    end

    def explore
      GunDog::TraceExplorer.new(self)
    end

    def call_records
      @call_records ||= []
    end

    def initialize(klass, suppression_set: [])
      @klass = klass
      @suppression_set = suppression_set
    end

    def collaborating_classes
      stack.collaborating_classes - [GunDog, klass]
    end

    def stack
      @stack ||= TraceStack.new(klass)
    end

    def finalize_report
      @call_records.freeze
      @stack.clear.freeze
      @finalized = true
    end

    def finalized?
      !!@finalized
    end

    def save(filename)
      File.open(filename, 'w') { |f| f.puts(to_json) }
    end


    def as_json
      {
        "klass" => klass.to_s,
        "collaborating_classes" => collaborating_classes.map { |k| k.json_encoded },
        "call_records" => call_records.map(&:as_json)
      }

    end


    def to_json
      MultiJson.dump(as_json)
    end

    def method_list
      @call_records.map(&:method_location)
    end
  end
end
