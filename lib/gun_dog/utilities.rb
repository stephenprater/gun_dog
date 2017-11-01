module GunDog
  module Utilities
    module RefinementIntrospection
      refine Module do
        def is_refinement?
          to_s.present? && to_s =~ /refinement/
        end

        def refined_class
          target = to_s[/#<refinement:(.*?)@/,1]
          return nil unless target
          const_get(target)
        rescue NoMethodError => e
          # hack - this is raised on AR objects if you call to_s before the
          # the inherited hooks are finished running
        end
      end
    end

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
