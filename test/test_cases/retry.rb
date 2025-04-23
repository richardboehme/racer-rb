$counter = 0
def foo
  if $counter == 0
    $counter += 1
    raise
  end
rescue
  retry
end

Racer.start
foo
Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
  method_name: foo
  method_kind: :instance
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
  params: []
