require "gun_dog/version"
require 'json'
require 'multi_json'
require 'active_support/core_ext/hash/slice'
require 'active_support/core_ext/string/filters'

module GunDog
  autoload :MethodOwnerStackFrame, 'gun_dog/method_owner_stack_frame'
  autoload :CallRecord, 'gun_dog/call_record'
  autoload :TraceMaker, 'gun_dog/trace_maker'
  autoload :TraceReport, 'gun_dog/trace_report'
  autoload :TraceStack, 'gun_dog/trace_stack'

  def self.trace(klass, &block)
    TraceMaker.new(klass, &block).exec
  end
end
