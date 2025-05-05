def foo
end

def bar
end

Racer.start(path_regex: /\Aapp\//)
foo
Racer.stop

# Files are written as tmp files
Racer.start(path_regex: /tmp/)
bar
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
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
  block_param:
