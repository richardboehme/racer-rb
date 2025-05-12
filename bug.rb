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
module A
  def foo; end
end

include A
Racer.start

foo

Racer.stop
