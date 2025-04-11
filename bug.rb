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


class Formatter
  def self.call(form)
    {}
  end
end

class MyForm

end

Racer.start_agent
Racer.start

Formatter.(MyForm.new)
Formatter.(MyForm.new)
Formatter.(MyForm.new)


Racer.stop
