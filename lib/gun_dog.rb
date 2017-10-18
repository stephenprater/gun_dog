require 'gun_dog/version'
require 'json'
require 'multi_json'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/string/filters'
require 'active_support/configurable'

module GunDog
  include ActiveSupport::Configurable

  config_accessor :suppress_methods do
    {}
  end

  autoload :MethodOwnerStackFrame, 'gun_dog/method_owner_stack_frame'
  autoload :CallRecord, 'gun_dog/call_record'
  autoload :TraceMaker, 'gun_dog/trace_maker'
  autoload :TraceReport, 'gun_dog/trace_report'
  autoload :TraceStack, 'gun_dog/trace_stack'
  autoload :TraceExplorer, 'gun_dog/trace_explorer'
  autoload :ClassEncoding, 'gun_dog/class_encoding'
  autoload :Utilities, 'gun_dog/utilities'

  class << self
    private def suppressed_methods_for_klass(klass)
      config.suppress_methods.values_at(*klass.ancestors).flatten.compact
    end
  end


  def self.trace(klass, &block)
    TraceMaker.new(klass, suppress: suppressed_methods_for_klass(klass), &block).exec
  end

  def self.load_trace(path)
    TraceReport.load(path)
  end
end
