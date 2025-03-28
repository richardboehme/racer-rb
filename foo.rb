require_relative "lib/racer"
require "benchmark"

def foo(a, b)
  a + b
end

Racer.start_agent

# wait for unix socket to be available
sleep 2

p Benchmark.measure {
  Racer.start

  5000.times do
    foo(1, 2)

    foo("a", "b")
  end

  Racer.stop
}
Racer.flush
