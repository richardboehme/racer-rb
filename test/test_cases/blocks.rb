def bar(&block)
  block.call(1, 2, kw: 3) do |&inner_block|
    6.instance_eval(&inner_block)
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

# We cannot collect traces for blocks that have no name, because we cannot
# match them to the correct method call.
baz do
  1
end

Racer.stop

__END__
---
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
    name: Integer
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::Constant
        name: Integer
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
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::Constant
          name: NilClass
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces:
        - !ruby/object:Racer::Trace::BlockTrace
          return_type: !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
          params: []
          block_param: !ruby/object:Racer::Trace::BlockParam
            name: inner_block
            traces:
            - !ruby/object:Racer::Trace::BlockTrace
              return_type: !ruby/object:Racer::Trace::Constant
                name: Integer
                type: :class
                path: []
                generic_arguments: []
              params: []
              block_param:
              self_type: !ruby/object:Racer::Trace::Constant
                name: Integer
                type: :class
                path: []
                generic_arguments: []
          self_type: !ruby/object:Racer::Trace::Constant
            name: Object
            type: :class
            path: []
            generic_arguments: []
      self_type: !ruby/object:Racer::Trace::Constant
        name: Object
        type: :class
        path: []
        generic_arguments: []
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
    name: Integer
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
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
            name: Symbol
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
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::Constant
          name: Symbol
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces: []
      self_type: !ruby/object:Racer::Trace::Constant
        name: Object
        type: :class
        path: []
        generic_arguments: []
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::Constant
        name: Array
        type: :class
        path: []
        generic_arguments:
        - - !ruby/object:Racer::Trace::Constant
            name: String
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Regexp
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: Float
            type: :class
            path: []
            generic_arguments: []
          - !ruby/object:Racer::Trace::Constant
            name: NilClass
            type: :class
            path: []
            generic_arguments: []
      params:
      - !ruby/object:Racer::Trace::Param
        name: :a
        type_name: !ruby/object:Racer::Trace::Constant
          name: String
          type: :class
          path: []
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::Constant
          name: Regexp
          type: :class
          path: []
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::Constant
          name: Float
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::Constant
          name: NilClass
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces: []
      self_type: !ruby/object:Racer::Trace::Constant
        name: Object
        type: :class
        path: []
        generic_arguments: []
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::Constant
        name: Integer
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
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :b
        type_name: !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        type: :optional
      - !ruby/object:Racer::Trace::Param
        name: :kw
        type_name: !ruby/object:Racer::Trace::Constant
          name: Integer
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_required
      - !ruby/object:Racer::Trace::Param
        name: :kw2
        type_name: !ruby/object:Racer::Trace::Constant
          name: NilClass
          type: :class
          path: []
          generic_arguments: []
        type: :keyword_optional
      block_param: !ruby/object:Racer::Trace::BlockParam
        name: block
        traces:
        - !ruby/object:Racer::Trace::BlockTrace
          return_type: !ruby/object:Racer::Trace::Constant
            name: Integer
            type: :class
            path: []
            generic_arguments: []
          params: []
          block_param: !ruby/object:Racer::Trace::BlockParam
            name: inner_block
            traces:
            - !ruby/object:Racer::Trace::BlockTrace
              return_type: !ruby/object:Racer::Trace::Constant
                name: Integer
                type: :class
                path: []
                generic_arguments: []
              params: []
              block_param:
              self_type: !ruby/object:Racer::Trace::Constant
                name: Integer
                type: :class
                path: []
                generic_arguments: []
          self_type: !ruby/object:Racer::Trace::Constant
            name: Object
            type: :class
            path: []
            generic_arguments: []
      self_type: !ruby/object:Racer::Trace::Constant
        name: Object
        type: :class
        path: []
        generic_arguments: []
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
    name: Integer
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name:
    traces: []
