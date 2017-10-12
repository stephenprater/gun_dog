module GunDog
  class MethodOwnerStackFrame < Struct.new(:klass, :method_name)
    def to_s
      "#{klass}##{method_name}"
    end
  end
end
