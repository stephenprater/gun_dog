module GunDog
  class TraceMaker
    attr_reader :trace_report, :return_trace, :call_trace, :klass

    def initialize(klass, &exec_block)
      @klass = klass
      @trace_report = TraceReport.new(klass)
      @trace_report.stack << MethodOwnerStackFrame.new(GunDog, :trace)
      @exec_block = exec_block
    end

    def exec
      set_trace

      call_trace.enable do
        return_trace.enable do
          @exec_block.call
        end
      end

      trace_report.finalize_report
      trace_report
    ensure
      call_trace.disable
      return_trace.disable
    end

    def set_trace
      set_return_trace
      set_call_trace
    end

    def set_return_trace
      @return_trace ||= TracePoint.new(:return) do |tp|
        trace_report.stack.pop
      end
    end

    def set_call_trace
      @call_trace ||= TracePoint.new(:call) do |tp|
        trace_report.stack << MethodOwnerStackFrame.new(tp.defined_class, tp.method_id)
        next unless tp.defined_class == klass || tp.defined_class == klass.singleton_class

        tp.disable

        call_record = CallRecord.new(klass, tp.method_id, class_method: tp.defined_class == klass.singleton_class)
        called_method = tp.self.method(tp.method_id)
        call_record.args = called_method.parameters.each.with_object({}) do |p, memo|
          memo[p.last] = tp.binding.local_variable_get(p.last).class
        end

        trace_report.call_records << call_record

        set_method_return_trace(call_record).enable

        tp.enable
      end
    end

    def set_method_return_trace(call_record)
      # instantiate a new return tracepoint to watch for the return of this
      # method only
      #
      TracePoint.new(:return) do |mrt|
        next if mrt.method_id != call_record.method_name
        mrt.disable
        call_record.return_value = mrt.return_value.class

        if trace_report.stack.internal_stack?
          call_record.internal = true
          call_record.stack = trace_report.stack.dup
        elsif trace_report.stack.cyclical_stack?
          call_record.cyclical = true
          call_record.stack = trace_report.stack.dup
        end
      end
    end
  end
end
