class A
  def self.singleton_method(b)
    b
  end

  def instance_method(a)
    a
  end
end

class B < A
  def self.singleton_method(c, d)
    super(c)
    [c, d]
  end

  def instance_method(c, d)
    super(c)
    [c, d]
  end
end

class C < A
end

Racer.start

B.singleton_method(1, 2)
B.new.instance_method(1, 2)

C.singleton_method(1)
C.new.instance_method(1)

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Integer
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: B
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Array
    singleton: false
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Integer
        singleton: false
        type: :class
        path: []
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :c
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :d
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Integer
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: B
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Array
    singleton: false
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Integer
        singleton: false
        type: :class
        path: []
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :c
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :d
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: C
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Integer
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: C
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: Integer
    singleton: false
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      singleton: false
      type: :class
      path: []
      generic_arguments: []
    type: :required
  block_param:
