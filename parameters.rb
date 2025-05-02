# require "racer"

def foo(a, b = 1, *args, kw:, kw2: 2, **kwargs, &block)
end

def bar(*, **, &)
end

def baz(...)

end

def nokey(**nil)
end

def arr_params((key, bar))
end


# Racer.start_agent

# Racer.start

foo(3, nil, "args", kw: :bar, kw2: /foo/, foo: :bar) do
  1 + 2
end

bar(a: 1)

# Racer.stop

p method(:foo).parameters
p method(:bar).parameters
p method(:baz).parameters
p method(:nokey).parameters
p method(:arr_params).parameters
