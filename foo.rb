require_relative "lib/racer"

def foo(a, b)
  a + b
end

Racer.start

foo(1, 2)

foo("a", "b")

Racer.stop

p "stopped script"

Racer.flush
