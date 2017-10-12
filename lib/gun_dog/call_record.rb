module GunDog
  class CallRecord
    attr_accessor :args, :return_value, :method_name
    attr_accessor :stack

    attr_writer :internal, :cyclical

    def self.from_json(json)
      cr = new(const_get(json['klass']),
          json['method_name'],
          class_method: json['class_method'])

      cr.instance_eval do
        @internal = json['internal']
        @cyclical = json['cyclical']
        @args = json['args']
        @return_value = json['return_value']
        @stack = json['stack']
      end

      cr
    end

    def initialize(klass, method_name, class_method: false)
      @klass = klass
      @method_name = method_name
      @class_method = class_method
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

    def class_method?
      !!@class_method
    end

    def to_s
      "def #{method_name}(#{type_signatures(args)}) => #{return_value}"
    end

    def as_json
      {
        "klass" => @klass,
        "method_name" => method_name,
        "class_method" => class_method?,
        "internal" => internal?,
        "cyclical" => cyclical?,
        "args" => args,
        "return_value" => return_value,
        "stack" => stack
      }.reject { |_,v| v.nil? }
    end

    private

    def type_signatures(args)
      args.each_pair.map { |k,v| "#{k} : #{v}" }.join(', ')
    end

    def method_separator
      class_method? ? '.' : '#'
    end
  end
end
