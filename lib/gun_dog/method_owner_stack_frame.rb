module GunDog
  class MethodOwnerStackFrame < Struct.new(:klass, :method_name)
    using ClassEncoding

    def to_s
      "#{klass}##{method_name}"
    end

    def as_json
      {
        "klass" => klass.json_encoded,
        "method_name" => method_name.to_s
      }
    end
  end
end
