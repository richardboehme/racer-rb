require_relative "lib/racer"
require "benchmark"

def foo(a, b)
  a + b
end

Racer.start_agent

p Benchmark.measure {

  Racer.start
  500000.times do
    foo(1, 2)

    foo("a", "b")
  end
  Racer.stop

  p "finished"

}
p Benchmark.measure {
  Racer.flush
}
