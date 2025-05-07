module A
  def foo
  end
end

class B
  include A
end

class C
  extend A
end

Racer.start

B.new.foo
C.foo

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: B
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: C
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
