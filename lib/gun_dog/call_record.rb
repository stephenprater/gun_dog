module GunDog
  class CallRecord
    using ClassEncoding

    attr_accessor :args, :return_value, :method_name, :extra_module
    attr_accessor :stack

    attr_writer :internal, :cyclical, :dynamic

    def self.from_json(json)
      cr = new(
        Utilities.get_class(json['klass']),
        json['method_name'],
        origin: json['origin']

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

    def initialize(klass, method_name, origin: false, extra_module: nil)
      @klass = klass
      @method_name = method_name
      @origin = origin
      @extra_module = extra_module
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
      @origin == :eigen
    end

    def origin
      @origin
    end

    def special_origin?
      [:meta, :included, :refinement].include?(@origin)
    end

    def origin_string
      case @origin
      when :meta
        '[generated]'
      when :included
        "[#{unbound_method.owner.name.to_s}]"
      when :extended
        "[#{extra_module.name.to_s} (extended)]"
      when :prepended
        "[#{unbound_method.owner.name.to_s} (prepended)]"
      when :refinement
        "[using #{extra_module.split('@')[1][0..-2]}]"
      else
        nil
      end
    end

    def unbound_method
      if class_method?
        @klass.method(method_name).unbind
      else
        @klass.instance_method(method_name)
      end
    end

    def call_record_signature
      "#{origin_string} \
        def #{class_method? ? "self." : nil}#{method_name}(#{type_signatures(args)}) : #{return_value.class} \
        #{ internal? ? " (internal)" : nil } \
        #{ cyclical? ? " (cyclical)" : nil } \
        #{ dynamic? ? " (dynamic)" : nil }".squish
    end

    def as_json
      {
        "klass" => @klass.json_encoded,
        "method_name" => method_name.to_s,
        "origin" => class_method?,
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
      elsif origin == :refinement
        '?'
      else
        args.each_pair.map { |k,v| "#{k} : #{v.class}" }.join(', ')
      end
    end

    def method_separator
      class_method? ? '.' : '#'
    end
  end
end
