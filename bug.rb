require "racer"
TracePoint.new(:return, :call, :rescue) do |tp|
  if tp.event == :call
    binding.irb
    p "call with method #{tp.method_id} #{tp.defined_class}"
  elsif tp.event == :rescue
    puts "rescue from method #{tp.method_id}"
  else
    puts "return with #{tp.method_id} -> #{tp.return_value}"
  end
end#.enable

def bar(&block)
  block.call(1, 2, kw: 3) do |&inner_block|
    inner_block.call
  end
end

def foo(&block)
  # other_block = -> {}
  # other_block.call()
  # yield(1, "string", kw: 1, kw2: :symbol)
  # yield("1", /tex/, kw: 3.4)
  bar(&block)
end


Racer.start_agent
Racer.start

foo do |a, b = 1, kw:, kw2: nil, &block|
  # other_block = -> {}
  # other_block.call()
  if block
    block.call do
      6
    end
  else
    # [a, b, kw, kw2]
  end
end

Racer.stop
