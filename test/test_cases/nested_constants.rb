module A
  class B
    class C
      def foo(a)
        a
      end
    end
  end
end

Racer.start
A::B::C.new.foo(A::B::C.new)
Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A::B::C
    singleton: false
    type: :class
    path:
    - !ruby/object:Racer::Trace::Constant::PathFragment
      name: :A
      type: :module
    - !ruby/object:Racer::Trace::Constant::PathFragment
      name: :B
      type: :class
    generic_arguments: []
  method_name: foo
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: A::B::C
    singleton: false
    type: :class
    path:
    - !ruby/object:Racer::Trace::Constant::PathFragment
      name: :A
      type: :module
    - !ruby/object:Racer::Trace::Constant::PathFragment
      name: :B
      type: :class
    generic_arguments: []
  params:
  - !ruby/object:Racer::Trace::Param
    name: :a
    type_name: !ruby/object:Racer::Trace::Constant
      name: A::B::C
      singleton: false
      type: :class
      path:
      - !ruby/object:Racer::Trace::Constant::PathFragment
        name: :A
        type: :module
      - !ruby/object:Racer::Trace::Constant::PathFragment
        name: :B
        type: :class
      generic_arguments: []
    type: :required
  block_param:
