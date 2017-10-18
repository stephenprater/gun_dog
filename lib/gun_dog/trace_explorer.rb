require 'active_support/core_ext/module/delegation'

module GunDog
  class TraceExplorer
    attr_reader :trace_report

    def initialize(trace_report)
      @trace_report = trace_report
    end

    def unique_call_signatures
      @trace_report.call_records.map(&:call_record_signature).uniq
    end

    def cyclical_methods
      @trace_report.call_records.select(&:cyclical?)
    end

    def internal_methods
      @trace_report.call_records.select(&:internal?)
    end

    def collaborating_local_classes
      @trace_report.collaborating_classes.select { |k| Utilities.local_locations_for_class(k).any? }
    end

    def collaborating_classes
      @trace_report.collaborating_classes
    end

    def trace
      @trace_report
    end

    def [](method_location)
      find_cache[method_location]
    end

    def methods
      find_cache.keys
    end

    def unique_traces(doc_name)
      find_cache[doc_name].map { |cr| cr.stack&.map(&:to_s) }.uniq.compact
    end

    def call_count
      find_cache.each_pair.with_object({}) { |(k,v), memo| memo[k] = v.count }
    end

    private

    def find_cache
      find_cache ||= @trace_report.call_records.group_by(&:method_location)
    end
  end
end
