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

class Foo
  def initialize
    1
  end
end

class Bar < Foo
  def initialize
    super()
  end
end

binding.irb
# Racer.start_agent
# Racer.start

Bar.new

# Racer.stop
