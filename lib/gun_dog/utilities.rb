module GunDog
  module Utilities
    class UnencodableClass; end

    def self.get_class(str)
      if str =~ /anonymous/
        Class.new(UnencodableClass) do |k|
          def json_encoded
            k
          end
        end
      else
        begin
          eval(str)
        rescue => e
          require 'pry'; binding.pry
          e.message
        end
      end
    end

    def self.local_locations_for_class(c)
      all_locations_for_class(c)
        .reject { |p| p =~ /(gem)|(rubies)|(eval)/ }
    end

    def self.all_locations_for_class(c)
      c.instance_methods
        .map { |m| c.instance_method(m) }
        .select { |m| m.owner == c }
        .map { |m| m.source_location&.first }
        .compact
        .uniq
    end
  end
end
