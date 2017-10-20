require 'active_support/core_ext/module/anonymous'
require 'method_source'

module GunDog
  class TraceMaker
    attr_reader :trace_report, :return_trace, :call_trace, :klass, :complete_call_list, :c_call_trace

    def initialize(klass, suppress: [], &exec_block)
      @klass = klass
      @trace_report = TraceReport.new(klass, suppression_set: build_suppression_set(suppress))
      @trace_report.stack << MethodOwnerStackFrame.new(GunDog, :trace)
      @ancestor_cache = {}
      @included_cache = {}
      @exec_block = exec_block
      @mrt_tracers = []
    end

    def exec
      set_trace
      wrap_accessor_functions

      call_trace.enable do
        return_trace.enable do
          @exec_block.call
        end
      end

      trace_report.finalize_report
      trace_report
    ensure
      @mrt_tracers.each(&:disable)
      unwrap_accessor_functions
      call_trace.disable
      return_trace.disable
    end

    def set_trace
      set_return_trace
      set_call_trace
    end

    def unwrap_accessor_functions
      accessor_methods.map do |m|
        klass.send(:remove_method, m)

        if m.to_s[-1] == '='
          klass.send :attr_writer, m[0..-2]
        else
          klass.send :attr_reader, m
        end
      end
    end

    def wrap_accessor_functions
      accessor_methods.map do |m|
        if m.to_s[-1] == '='
          klass.module_eval <<~RUBY, __FILE__, __LINE__
              def #{m.to_s}(arg1)
                @#{m.to_s[0..-2]} = arg1
              end
          RUBY
        else
          klass.module_eval <<~RUBY, __FILE__, __LINE__
              def #{m.to_s}
                @#{m.to_s}
              end
          RUBY
        end
      end
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

        binding_class = tp.binding.receiver.class
        trace_type = trace_method(binding_class, tp.defined_class, tp.self)
        method_id = tp.binding.eval('__callee__') || tp.method_id

        # puts "#{method_id} => #{trace_type} (#{tp.defined_class})" if trace_type

        unless trace_type
          tp.enable
          next
        end

        call_record = nil

        if trace_type == :refinement
          call_record = CallRecord.new(
            klass,
            method_id,
            origin: trace_type,
            extra_module: tp.defined_class.to_s
          )
        else
          called_method = if trace_type == :meta || trace_type == :included
                            tp.binding.eval('self').method(method_id)
                          else
                            tp.self.method(tp.method_id)
                          end

          call_record = CallRecord.new(
            klass,
            called_method.name,
            origin: trace_type,
            extra_module: (tp.defined_class if trace_type == :extended)
          )

          call_record.args = called_method.parameters.each.with_object({}) do |p, memo|
            memo[p.last] = tp.binding.local_variable_get(p.last)
          end
        end

        trace_report.call_records << call_record

        mrt = set_method_return_trace(call_record)
        @mrt_tracers << mrt
        mrt.enable

        tp.enable
      end
    end

    def trace_method(binding_class, defined_class, obj)
      return :eigen if defined_class == klass.singleton_class
      return false if binding_class != klass
      return :refinement if defined_class.to_s =~ /refinement/
      return :meta if klass < defined_class && defined_class.anonymous?
      return :prepended if klass < defined_class && prepended?(defined_class)
      return :included if klass < defined_class && after_super?(defined_class)
      return :instance if defined_class == klass
      return :extended if obj.singleton_class < defined_class && after_super?(defined_class)
      false
    end

    def after_super?(defined_class)
      return true unless klass.superclass != Object

      if @ancestor_cache.has_key?(defined_class)
        @ancestor_cache[defined_class]
      else
        ancestors = klass.ancestors
        @ancestor_cache[defined_class] = ancestors.index(klass.superclass) > ancestors.index(defined_class)
      end
    end

    def prepended?(defined_class)
      if @included_cache.has_key?(defined_class)
        @included_cache[defined_class]
      else
        ancestors = klass.ancestors
        @included_cache[defined_class] = ancestors.index(klass) > ancestors.index(defined_class)
      end
    end

    def set_method_return_trace(call_record)
      # instantiate a new return tracepoint to watch for the return of this
      # method only
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

    private

    def accessor_methods
      @accessor_methods ||= klass.instance_methods.map { |m| klass.instance_method(m) }
        .select { |m| m.owner == klass }
        .select { |m| m.source =~ /attr/ }
        .map { |m| m.name }
    end

    def build_suppression_set(suppression_list)
      suppression_list.map { |method_id|
        begin
          if class_method = method_id[/self\.(.*)/,1]
            klass.method(class_method).unbind
          else
            klass.instance_method(method_id)
          end
        rescue NameError
          nil
        end
      }.uniq.to_set
    end
  end
end
