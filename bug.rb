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


class A
  class B
  end
end

class Foo
  module Bar
    class Baz
      def self.foo(a)
        A::B.new
      end
    end
  end
end

Racer.start_agent
Racer.start

Foo::Bar::Baz.foo(1)


Racer.stop
