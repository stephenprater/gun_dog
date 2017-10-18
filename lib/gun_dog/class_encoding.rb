module GunDog
  module ClassEncoding
    refine Class do
      def json_encoded
        if singleton_class?
          "#{ObjectSpace.each_object(self).first}.singleton_class"
        else
          name || "(anonymous subclass of #{superclass.name}"
        end
      end
    end

    refine Module do
      def json_encoded
        return name if name
        "(anonymous module extended to an instance of #{ObjectSpace.each_object(self).first.class})"
      end
    end
  end
end
