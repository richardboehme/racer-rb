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

nilkey(3)

# RACER-TODO: This reports as 0 arguments
# arr_params([2, 3])
# RACER-TODO: Should we type **nil?

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
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :required_pos
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      type: :class
      path: []
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :optional_pos
    type_name: !ruby/object:Racer::Trace::Constant
      name: NilClass
      type: :class
      path: []
      generic_arguments: []
    type: :optional
  - !ruby/object:Racer::Trace::Param
    name: :args
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments:
      - - !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :required_kw
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      type: :class
      path: []
      generic_arguments: []
    type: :keyword_required
  - !ruby/object:Racer::Trace::Param
    name: :optional_kw
    type_name: !ruby/object:Racer::Trace::Constant
      name: Symbol
      type: :class
      path: []
      generic_arguments: []
    type: :keyword_optional
  - !ruby/object:Racer::Trace::Param
    name: :other_kwargs
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
      - - !ruby/object:Racer::Trace::Constant
          name: Symbol
          type: :class
          path: []
          generic_arguments: []
        - !ruby/object:Racer::Trace::Constant
          name: Regexp
          type: :class
          path: []
          generic_arguments: []
    type: :keyword_rest
  - !ruby/object:Racer::Trace::Param
    name: :block
    type_name: !ruby/object:Racer::Trace::Constant
      name: Proc
      type: :class
      path: []
      generic_arguments: []
    type: :block
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: bar
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      type: :class
      path: []
      generic_arguments: []
    type: :required
  - !ruby/object:Racer::Trace::Param
    name: :rest
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
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :b
    type_name: !ruby/object:Racer::Trace::Constant
      name: String
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
  method_name: anon
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :*
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :**
    type_name: !ruby/object:Racer::Trace::Constant
      name: Hash
      type: :class
      path: []
      generic_arguments: []
    type: :keyword_rest
  - !ruby/object:Racer::Trace::Param
    name: :&
    type_name: !ruby/object:Racer::Trace::Constant
      name: Proc
      type: :class
      path: []
      generic_arguments: []
    type: :block
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: baz
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :*
    type_name: !ruby/object:Racer::Trace::Constant
      name: Array
      type: :class
      path: []
      generic_arguments: []
    type: :rest
  - !ruby/object:Racer::Trace::Param
    name: :**
    type_name: !ruby/object:Racer::Trace::Constant
      name: Hash
      type: :class
      path: []
      generic_arguments: []
    type: :keyword_rest
  - !ruby/object:Racer::Trace::Param
    name: :&
    type_name: !ruby/object:Racer::Trace::Constant
      name: Proc
      type: :class
      path: []
      generic_arguments: []
    type: :block
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: nilkey
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: Integer
      type: :class
      path: []
      generic_arguments: []
    type: :required
