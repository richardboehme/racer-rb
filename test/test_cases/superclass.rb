class A
  def self.singleton_method(b)
    b
  end

  def instance_method(a)
    a
  end

  def private_method
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

  private def private_method
    super
  end
end

class C < A
end

Racer.start

B.singleton_method(1, 2)
B.new.instance_method(1, 2)
B.new.send(:private_method)

C.singleton_method(1)
C.new.instance_method(1)

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: A
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: B
    anonymous: false
    type: :class
    superclass: A
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::Integer
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Comparable
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Numeric
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - Comparable
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Integer
    anonymous: false
    type: :class
    superclass: Numeric
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::Integer
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: B
    singleton: false
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Integer
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :c
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :d
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::Array
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Enumerable
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Array
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::Array
    - Enumerable
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: B
    singleton: false
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Integer
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :c
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :d
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::NilClass
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: NilClass
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::NilClass
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: B
    singleton: false
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: C
    anonymous: false
    type: :class
    superclass: A
    included_modules: []
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: instance_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
