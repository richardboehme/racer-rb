class Foo
  def self.foo(a, &block)
    if block
      block.call(a)
    end

    a
  end
end

class Bar
end

Racer.start

# Do not report Class constants as anonymous
Foo.foo(Foo)
Foo.foo([Foo])
Foo.foo({ Foo => Foo })
Foo.foo(Bar)

Foo.foo(Foo) { |a| a }
Foo.foo([Foo]) { |a| a }
Foo.foo({ Foo => Foo }) { |a| a }
Foo.foo(Bar) { |a| a }

Racer.stop
__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Class
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Class
      singleton: false
      generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces: []
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: Foo
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Module
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Class
    anonymous: false
    type: :class
    superclass: Module
    included_modules: []
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces: []
  constant_updates:
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
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Hash
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces: []
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::Hash
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Hash
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::Hash
    - Enumerable
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Class
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Class
      singleton: false
      generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Class
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Class
      singleton: false
      generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
        type: :optional
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: PP::PPMethods
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PrettyPrint
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PP
    anonymous: false
    type: :class
    superclass: PrettyPrint
    included_modules:
    - PP::PPMethods
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PP::ObjectMixin
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::Object
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Object
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - PP::ObjectMixin
    - JSON::Ext::Generator::GeneratorMethods::Object
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Array
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Class
            singleton: false
            generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Array
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Class
              singleton: false
              generic_arguments: []
        type: :optional
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Hash
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Hash
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Class
            singleton: false
            generic_arguments: []
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Class
            singleton: false
            generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Hash
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Class
              singleton: false
              generic_arguments: []
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Class
              singleton: false
              generic_arguments: []
        type: :optional
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Class
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Class
      singleton: false
      generic_arguments: []
    type: :required
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Class
        singleton: false
        generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Class
          singleton: false
          generic_arguments: []
        type: :optional
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
