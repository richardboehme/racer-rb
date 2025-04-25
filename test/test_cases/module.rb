module A
  def foo
  end
end

class B
  include A
end

Racer.start

B.new.foo

Racer.stop

# RACER-TODO: We should probably also return B as a method owner or something

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    type: :module
    path: []
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
