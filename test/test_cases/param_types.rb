def foo(required_pos, optional_pos = 1, *args, required_kw:, optional_kw: 1, **other_kwargs, &block)
end

def bar(a, *rest, b)
end

def anon(*, **, &)
end

def baz(...)
end

def nilkey(a, **nil)
end

def arr_params((key, bar))
end

def block_without_parameter
end

Racer.start

foo(3, nil, "args", "more args", required_kw: 4, optional_kw: :bar, foo: :baz, "test-symbol": /regex/) do
  1 + 2
end

bar(1, 2, 3, 4, 5, "6")

anon(1, 2, foo: :bar) do
end

baz(1, 2, foo: :bar) do
  3 + 4
end

block_without_parameter do
end

block_without_parameter(&-> {  })

nilkey(3)

arr_params([2, 3])
# RACER-TODO: Should we type **nil?

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :required_pos
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :optional_pos
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: NilClass
      singleton: false
      generic_arguments: []
    type: :optional
  - !ruby/object:Racer::Trace::Param
    name: :args
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: String
          singleton: false
          generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :required_kw
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Integer
      singleton: false
      generic_arguments: []
    type: :keyword_required
  - !ruby/object:Racer::Trace::Param
    name: :optional_kw
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Symbol
      singleton: false
      generic_arguments: []
    type: :keyword_optional
  - !ruby/object:Racer::Trace::Param
    name: :other_kwargs
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Symbol
          singleton: false
          generic_arguments: []
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Symbol
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Regexp
          singleton: false
          generic_arguments: []
    type: :keyword_rest
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces: []
  constant_updates:
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
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::String
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::String::Extend
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: String
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::String
    - Comparable
    prepended_modules: []
    extended_modules:
    - JSON::Ext::Generator::GeneratorMethods::String::Extend
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
  - !ruby/object:Racer::Trace::Constant
    name: Symbol
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - Comparable
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Regexp
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
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
    name: Object
    singleton: false
    generic_arguments: []
  method_name: bar
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
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
  - !ruby/object:Racer::Trace::Param
    name: :rest
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: String
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: anon
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :*
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :**
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
      singleton: false
      generic_arguments: []
    type: :keyword_rest
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: baz
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :*
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :**
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
      singleton: false
      generic_arguments: []
    type: :keyword_rest
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: block_without_parameter
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: block_without_parameter
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: nilkey
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
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
    name: Object
    singleton: false
    generic_arguments: []
  method_name: arr_params
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name:
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
      singleton: false
      generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
