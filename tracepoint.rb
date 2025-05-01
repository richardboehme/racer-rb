# tp2 = TracePoint.new(:call) do |tp|
#   p [:call, caller[0..2], Thread.current.native_thread_id]
# end
require_relative "./test"

tp = TracePoint.new(:call) do |tp|
  # p [:return, caller[0..2]]
  p caller_locations(0, 1).first.path
  # p [
  #   tp.path,
  #   tp.lineno,
  #   tp.callee_id, # name of method that was called -> in path:lineno
  #   tp.method_id, # name of actual method
  #   tp.self,
  #   # tp.return_value,
  #   tp.parameters.map { |(type, name)| [name, tp.binding.local_variable_get(name)] }
  # ]
end
# tp2.enable
# require_relative "lib/racer"
tp.enable

# Racer.start_agent

# Racer.start

# class Bar
#   def self.foo
#   end

#   def foo(c, d)
#   end
# end

# class Foo < Bar
#   def self.foo(a)
#     super()
#   end

#   def foo(a, b)
#     super
#     [a, b]
#   end
# end

# # f = Foo.new

# Foo.new.foo(1, 2)

# module A
#   def foo
#   end

#   def self.bar

#   end
# end

# class B
#   extend A
# end

# class C
#   include A
# end

# A.bar
foo

Foo.foo

class Bar < Foo
  foo
end

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
