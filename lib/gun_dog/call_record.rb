module GunDog
  class CallRecord
    using ClassEncoding

    attr_accessor :args, :return_value, :method_name
    attr_accessor :stack

    attr_writer :internal, :cyclical, :dynamic

    def self.from_json(json)
      cr = new(
        Utilities.get_class(json['klass']),
        json['method_name'],
        class_method: json['class_method'],
        generated: json['generated']
      )

      cr.instance_eval do
        @internal = json['internal']
        @cyclical = json['cyclical']
        @args = json['args']
        @return_value = json['return_value']
        @stack = TraceStack.from_array(klass: @klass, stack: json['stack']) if json['stack']
      end

      cr
    end

    def initialize(klass, method_name, class_method: false, generated: false)
      @klass = klass
      @method_name = method_name
      @class_method = class_method
      @generated = generated
    end

    def method_location
      "#{@klass}#{method_separator}#{method_name}"
    end

    def internal?
      !!@internal
    end

    def cyclical?
      !!@cyclical
    end

    def dynamic?
      !!@dynamic
    end

    def class_method?
      !!@class_method
    end

    def generated?
      !!@generated
    end

    def unbound_method
      if class_method?
        @klass.method(method_name).unbind
      else
        @klass.instance_method(method_name)
      end
    end

    def call_record_signature
      "#{generated? ? "[generated] " : nil } \
        def #{class_method? ? "self." : nil}#{method_name}(#{type_signatures(args)}) : #{return_value.class} \
        #{ internal? ? " (internal)" : nil } \
        #{ cyclical? ? " (cyclical)" : nil } \
        #{ dynamic? ? " (dynamic)" : nil }".squish
    end

    def as_json
      {
        "klass" => @klass.json_encoded,
        "method_name" => method_name.to_s,
        "class_method" => class_method?,
        "generated" => generated?,
        "internal" => internal?,
        "cyclical" => cyclical?,
        "dynamic" => dynamic?,
        "args" => args.each_pair.with_object({}) { |(k,v), memo| memo[k.to_s] = v},
        "return_value" => return_value,
        "stack" => stack&.as_json
      }.reject { |_,v| v.nil? }
    end

    private

    def type_signatures(args)
      if method_name == :method_missing
        #TODO pass v here back through this method to show the type signatures for each method rather than
        # individual arguments
        args.each_pair.map { |k,v| "#{k} : #{v ? v.to_s : v.class}" }.join(', ')
      else
        args.each_pair.map { |k,v| "#{k} : #{v.class}" }.join(', ')
      end
    end

    def method_separator
      class_method? ? '.' : '#'
    end
  end
end
