class A
  def self.foo
  end
end

module B
  def self.bar
  end
end

Racer.start

A.foo
B.bar

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    type: :class
    path: []
  method_name: foo
  method_kind: :singleton
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: B
    type: :module
    path: []
  method_name: bar
  method_kind: :singleton
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
  params: []
