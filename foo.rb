require "racer"

def foo(a, b)
  a + b
end

Racer.start

foo(1, 2)

foo("a", "b")

p Racer.stop

p "stopped script"

# Racer.flush
