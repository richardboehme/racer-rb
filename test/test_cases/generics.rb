def foo(a)
  a
end

module A
  class B
  end
end

Racer.start

foo([1, "2", [], /fo/, A::B.new])
foo({ a: 1, "b" => "c", c: /foo/, A::B.new => "bar" })
foo({})
foo([])
foo([[1, "2", [3], { a: 1 }]])
foo({a: [1, 2], b: { a: 1, b: [3] }, [1, 2, [""]] => :foo })

Racer.stop

Racer.start(max_generic_depth: 3)
foo([[[3, []]]])
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
        name: Array
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: Regexp
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: A::B
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
          name: Integer
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: String
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Array
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Regexp
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: A::B
          singleton: false
          generic_arguments: []
    type: :required
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: Object
    anonymous: true
    type: :class
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
    name: Regexp
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: A
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: A::B
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Hash
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Symbol
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: String
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: A::B
        singleton: false
        generic_arguments: []
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Integer
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: String
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: Regexp
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
          name: Symbol
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: String
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: A::B
          singleton: false
          generic_arguments: []
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Integer
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: String
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Regexp
          singleton: false
          generic_arguments: []
    type: :required
  block_param:
  constant_updates:
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Hash
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Hash
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::ConstantInstance
      name: Array
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
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
            name: Array
            singleton: false
            generic_arguments: []
          - !ruby/object:Racer::Trace::ConstantInstance
            name: Hash
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
              name: Array
              singleton: false
              generic_arguments: []
            - !ruby/object:Racer::Trace::ConstantInstance
              name: Hash
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Hash
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Symbol
        singleton: false
        generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: Array
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Integer
            singleton: false
            generic_arguments: []
          - !ruby/object:Racer::Trace::ConstantInstance
            name: Array
            singleton: false
            generic_arguments: []
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Array
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Integer
            singleton: false
            generic_arguments: []
      - !ruby/object:Racer::Trace::ConstantInstance
        name: Hash
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Symbol
            singleton: false
            generic_arguments: []
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Integer
            singleton: false
            generic_arguments: []
          - !ruby/object:Racer::Trace::ConstantInstance
            name: Array
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
      name: Hash
      singleton: false
      generic_arguments:
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Symbol
          singleton: false
          generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Array
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Integer
              singleton: false
              generic_arguments: []
            - !ruby/object:Racer::Trace::ConstantInstance
              name: Array
              singleton: false
              generic_arguments: []
      - - !ruby/object:Racer::Trace::ConstantInstance
          name: Array
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Integer
              singleton: false
              generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Hash
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Symbol
              singleton: false
              generic_arguments: []
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Integer
              singleton: false
              generic_arguments: []
            - !ruby/object:Racer::Trace::ConstantInstance
              name: Array
              singleton: false
              generic_arguments: []
        - !ruby/object:Racer::Trace::ConstantInstance
          name: Symbol
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: Array
    singleton: false
    generic_arguments:
    - - !ruby/object:Racer::Trace::ConstantInstance
        name: Array
        singleton: false
        generic_arguments:
        - - !ruby/object:Racer::Trace::ConstantInstance
            name: Array
            singleton: false
            generic_arguments:
            - - !ruby/object:Racer::Trace::ConstantInstance
                name: Integer
                singleton: false
                generic_arguments: []
              - !ruby/object:Racer::Trace::ConstantInstance
                name: Array
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
          name: Array
          singleton: false
          generic_arguments:
          - - !ruby/object:Racer::Trace::ConstantInstance
              name: Array
              singleton: false
              generic_arguments:
              - - !ruby/object:Racer::Trace::ConstantInstance
                  name: Integer
                  singleton: false
                  generic_arguments: []
                - !ruby/object:Racer::Trace::ConstantInstance
                  name: Array
                  singleton: false
                  generic_arguments: []
    type: :required
  block_param:
  constant_updates: []
