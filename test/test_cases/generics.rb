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

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Array
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Integer
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: String
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Array
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Regexp
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: A::B
        type: :class
        path:
        - !ruby/object:Racer::Trace::Constant::PathFragment
          name: :A
          type: :module
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments:
      - - !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Array
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Regexp
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: A::B
          type: :class
          path:
          - !ruby/object:Racer::Trace::Constant::PathFragment
            name: :A
            type: :module
          generic_arguments: []
    type: :required
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Hash
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Symbol
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: String
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: A::B
        type: :class
        path:
        - !ruby/object:Racer::Trace::Constant::PathFragment
          name: :A
          type: :module
        generic_arguments: []
    - - !ruby/object:Racer::Trace::Constant
        name: Integer
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: String
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Regexp
        type: :class
        path: []
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Hash
      type: :class
      path: []
      generic_arguments:
      - - !ruby/object:Racer::Trace::Constant
          name: Symbol
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: A::B
          type: :class
          path:
          - !ruby/object:Racer::Trace::Constant::PathFragment
            name: :A
            type: :module
          generic_arguments: []
      - - !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Regexp
          type: :class
          path: []
          generic_arguments: []
    type: :required
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Hash
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Hash
      type: :class
      path: []
      generic_arguments: []
    type: :required
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Array
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments: []
    type: :required
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Array
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Array
        type: :class
        path: []
        generic_arguments:
        - - !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: String
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Array
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Hash
            type: :class
            path: []
            generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments:
      - - !ruby/object:Racer::Trace::Constant
          name: Array
          type: :class
          path: []
          generic_arguments:
          - - !ruby/object:Racer::Trace::Constant
              name: Integer
              type: :class
              path: []
              generic_arguments: []
            - !ruby/object:Racer::Trace::Constant
              name: String
              type: :class
              path: []
              generic_arguments: []
            - !ruby/object:Racer::Trace::Constant
              name: Array
              type: :class
              path: []
              generic_arguments: []
            - !ruby/object:Racer::Trace::Constant
              name: Hash
              type: :class
              path: []
              generic_arguments: []
    type: :required
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: Hash
    type: :class
    path: []
    generic_arguments:
    - - !ruby/object:Racer::Trace::Constant
        name: Symbol
        type: :class
        path: []
        generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Array
        type: :class
        path: []
        generic_arguments:
        - - !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Array
            type: :class
            path: []
            generic_arguments: []
    - - !ruby/object:Racer::Trace::Constant
        name: Array
        type: :class
        path: []
        generic_arguments:
        - - !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Hash
        type: :class
        path: []
        generic_arguments:
        - - !ruby/object:Racer::Trace::Constant
            name: Symbol
            type: :class
            path: []
            generic_arguments: []
        - - !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Array
            type: :class
            path: []
            generic_arguments: []
      - !ruby/object:Racer::Trace::Constant
        name: Symbol
        type: :class
        path: []
        generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Hash
      type: :class
      path: []
      generic_arguments:
      - - !ruby/object:Racer::Trace::Constant
          name: Symbol
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Array
          type: :class
          path: []
          generic_arguments:
          - - !ruby/object:Racer::Trace::Constant
              name: Integer
              type: :class
              path: []
              generic_arguments: []
            - !ruby/object:Racer::Trace::Constant
              name: Array
              type: :class
              path: []
              generic_arguments: []
      - - !ruby/object:Racer::Trace::Constant
          name: Array
          type: :class
          path: []
          generic_arguments:
          - - !ruby/object:Racer::Trace::Constant
              name: Integer
              type: :class
              path: []
              generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Hash
          type: :class
          path: []
          generic_arguments:
          - - !ruby/object:Racer::Trace::Constant
              name: Symbol
              type: :class
              path: []
              generic_arguments: []
          - - !ruby/object:Racer::Trace::Constant
              name: Integer
              type: :class
              path: []
              generic_arguments: []
            - !ruby/object:Racer::Trace::Constant
              name: Array
              type: :class
              path: []
              generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Symbol
          type: :class
          path: []
          generic_arguments: []
    type: :required
