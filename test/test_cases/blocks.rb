def bar(&block)
  block.call(1, 2, kw: 3) do |&inner_block|
    6.instance_eval(&inner_block)
  end
end

class Foo
  def self.foo(&block)
    instance_eval(&block)
  end
end

def foo(&block)
  other_block = -> {}
  other_block.call()
  yield(1, "string", kw: 1, kw2: :symbol)
  yield("1", /tex/, kw: 3.4)
  bar(&block)
end

def baz
  yield
end

Racer.start

foo do |a, b = 1, kw:, kw2: nil, &block|
  if block
    block.call do
      self.+(3)
    end
  else
    [a, b, kw, kw2]
  end
end

foo {}

# self type should be a singleton of Foo
Foo.foo do
end

# We cannot collect traces for blocks that have no name, because we cannot
# match them to the correct method call.
baz do
  1
end

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: bar
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
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
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: NilClass
          singleton: false
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces:
        - !ruby/object:Racer::Trace::BlockTrace
          return_type: !ruby/object:Racer::Trace::ConstantInstance
            name: Integer
            singleton: false
            generic_arguments: []
          params: []
          block_param: !ruby/object:Racer::Trace::BlockParam
            name: inner_block
            traces:
            - !ruby/object:Racer::Trace::BlockTrace
              return_type: !ruby/object:Racer::Trace::ConstantInstance
                name: Integer
                singleton: false
                generic_arguments: []
              params: []
              block_param:
              self_type: !ruby/object:Racer::Trace::ConstantInstance
                name: Integer
                singleton: false
                generic_arguments: []
          self_type: !ruby/object:Racer::Trace::ConstantInstance
            name: Object
            singleton: false
            generic_arguments: []
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
    name: Symbol
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - Comparable
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
    name: Object
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Array
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Integer
            singleton: false
            generic_arguments: []
          - !ruby/object:Racer::Trace::ConstantInstance
            name: String
            singleton: false
            generic_arguments: []
          - !ruby/object:Racer::Trace::ConstantInstance
            name: Symbol
            singleton: false
            generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: String
          singleton: false
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::ConstantInstance
          name: Symbol
          singleton: false
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces: []
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: bar
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: NilClass
        singleton: false
        generic_arguments: []
      params: []
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: NilClass
        singleton: false
        generic_arguments: []
      params: []
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
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: NilClass
        singleton: false
        generic_arguments: []
      params: []
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Foo
        singleton: true
        generic_arguments: []
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: Foo
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_callee:
  method_name: baz
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Integer
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
  constant_updates: []
