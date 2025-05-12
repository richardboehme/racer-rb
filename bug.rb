require "racer"
TracePoint.new(:call) do |tp|
  if tp.event == :call
    p [tp.self, tp.defined_class]
    # p "call with method #{tp.method_id} #{tp.defined_class}"
  elsif tp.event == :rescue
    puts "rescue from method #{tp.method_id}"
  else
    puts "return with #{tp.method_id} -> #{tp.return_value}"
  end
end#.enable

Racer.start_agent
def bar(&block)
  block.call(1, 2, kw: 3) do |&inner_block|
    6.instance_eval(&inner_block)
  end
end

class Foo
  def self.foo(&block)
    instance_eval(&block)
  end
end

def foo(&block)
  other_block = -> {}
  other_block.call()
  yield(1, "string", kw: 1, kw2: :symbol)
  yield("1", /tex/, kw: 3.4)
  bar(&block)
end

def baz
  yield
end

Racer.start

foo do |a, b = 1, kw:, kw2: nil, &block|
  if block
    block.call do
      self.+(3)
    end
  else
    [a, b, kw, kw2]
  end
end

# self type should be a singleton of Foo
Foo.foo do
end

# We cannot collect traces for blocks that have no name, because we cannot
# match them to the correct method call.
baz do
  1
end

Racer.stop
