class Foo
  def foo
  end
end

a = Class.new(Foo) do
  def bar
  end
end

Racer.start

a.new.bar
a.new.foo

Racer.stop
__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: bar
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
