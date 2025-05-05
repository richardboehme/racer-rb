$counter = 0
def foo
  if $counter == 0
    $counter += 1
    raise
  end
rescue
  retry
end

def bar(&block)
  yield
end

Racer.start
foo

$counter = 0
bar do
  if $counter == 2
    $counter += 1
    raise
  end
rescue
  retry
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
  method_name: foo
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
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
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::Constant
        name: NilClass
        type: :class
        path: []
        generic_arguments: []
      params: []
      block_param:
      self_type: !ruby/object:Racer::Trace::Constant
        name: Object
        type: :class
        path: []
        generic_arguments: []
