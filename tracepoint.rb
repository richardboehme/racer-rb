# tp2 = TracePoint.new(:call) do |tp|
#   p [:call, caller[0..2], Thread.current.native_thread_id]
# end

$tp = TracePoint.new(:call) do |tp|
  # p [:return, caller[0..2]]
  binding.irb
  p [tp.self.class, tp.defined_class]
  #   tp.path,
  #   tp.lineno,
  #   tp.callee_id, # name of method that was called -> in path:lineno
  #   tp.method_id, # name of actual method
  #   tp.self,
  #   # tp.return_value,
  #   tp.parameters.map { |(type, name)| [name, tp.binding.local_variable_get(name)] }
  # ]
end.enable
# tp2.enable
# require_relative "lib/racer"

# Racer.start_agent

# Racer.start

# class Foo
#   def self.foo(&block)
#     block.call
#   end#


#   foo do |a|
#     a
#   end
# end

module A
  def foo
  end
end

include A

foo

# B.foo
# C.new.foo

# Foo.foo(1)
# f.foo(1, 2)

# module A
#   def self.foo
#   end
# end
# A.foo


# Racer.stop

# Racer.start

# f.foo("a", "b")

# # tp.disable

# Racer.stop

# tp.disable
# tp2.disable

# Problem: We cannot get the original parameters in the return event because they might have been modified
# To connect those we need to keep a call stack and listen to both (call and return) events.
# Later the call stack must be thread local, otherwise it might get mixed up.
# Not sure if there is an easier method for this. This might also give us some performance penalty because
# we now listen to two events.
