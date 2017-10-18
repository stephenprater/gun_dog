require 'active_support/core_ext/module/anonymous'

module GunDog
  class TraceMaker
    attr_reader :trace_report, :return_trace, :call_trace, :klass, :complete_call_list

    def initialize(klass, suppress: [], &exec_block)
      @klass = klass
      @trace_report = TraceReport.new(klass, suppression_set: build_suppression_set(suppress))
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

        tp.disable

        binding_class = tp.binding.eval('self').class
        trace_type = trace_method(binding_class, tp.defined_class)

        unless trace_type
          tp.enable
          next
        end

        method_id = tp.binding.eval('__callee__') || tp.method_id

        called_method = if trace_type == :meta
          tp.binding.eval('self').method(method_id)
        else
          tp.self.method(tp.method_id)
        end

        # next if trace_report.suppression_set.include?(called_method.unbind)

        call_record = CallRecord.new(
          klass,
          called_method.name,
          class_method: trace_type == :eigen,
          generated: trace_type == :meta
        )

        call_record.args = called_method.parameters.each.with_object({}) do |p, memo|
          memo[p.last] = tp.binding.local_variable_get(p.last)
        end

        trace_report.call_records << call_record

        set_method_return_trace(call_record).enable

        tp.enable
      end
    end

    def trace_method(binding_class, defined_class)
      return :eigen if defined_class == klass.singleton_class
      return false if binding_class != klass
      return :meta if binding_class < defined_class && defined_class.anonymous?
      return :instance if defined_class == klass
      false
    end

    def set_method_return_trace(call_record)
      # instantiate a new return tracepoint to watch for the return of this
      # method only
      #
      TracePoint.new(:return) do |mrt|
        method_id = mrt.binding.eval('__callee__') || mrt.method_id
        next if method_id != call_record.method_name
        mrt.disable
        call_record.return_value = mrt.return_value

        if trace_report.stack.internal_stack?
          call_record.internal = true
          call_record.stack = trace_report.stack.since_first_klass_entry
        elsif trace_report.stack.cyclical_stack?
          call_record.cyclical = true
          call_record.stack = trace_report.stack.since_first_klass_entry
        end

        if trace_report.stack.dynamic_stack?
          call_record.dynamic = true
          call_record.stack = trace_report.stack.since_first_klass_entry
        end
      end
    end

    def build_suppression_set(suppression_list)
      suppression_list.map { |method_id|
        if class_method = method_id[/self\.(.*)/,1]
          klass.method(class_method).unbind
        else
          klass.instance_method(method_id)
        end
      }.uniq.to_set
    end
  end
end
