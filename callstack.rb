$call_stack = {}

tp = TracePoint.new(:call, :return) do |tp|
  next if tp.method_id == :inspect
  case tp.event
  when :call
    $call_stack[Fiber.current.object_id] ||= []
    $call_stack[Fiber.current.object_id] << tp.method_id
  when :return
    prev = $call_stack[Fiber.current.object_id].pop
    p [prev, tp.method_id]
  end
end

$fiber = Fiber.new do
  loop do
    bar
  end
end

def foo(a, b)
  # call stack should include foo
  #p $call_stack
  $fiber.resume
  #p $call_stack
  # call stack should include bar
  a + b
end

def bar
  Fiber.yield
  nil
end

tp.enable

10.times do
  foo(1, 2)
end
tp.disable

