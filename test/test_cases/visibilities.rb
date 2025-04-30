class Foo
  class << self
    def public_singleton_method
      private_singleton_method
      protected_singleton_method
    end

    private def private_singleton_method
    end

    protected def protected_singleton_method
    end
  end

  def public_method
    private_method
    protected_method
  end

  private def private_method
  end

  protected def protected_method
  end
end

module A
  class << self
    def public_singleton_method
      private_singleton_method
      protected_singleton_method
    end

    private def private_singleton_method
    end

    protected def protected_singleton_method
    end
  end

  def public_method
    private_method
    protected_method
  end

  private def private_method
  end

  protected def protected_method
  end
end

include A

Racer.start

Foo.public_singleton_method
Foo.new.public_method
public_method
A.public_singleton_method

Racer.stop

__END__
---
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: private_singleton_method
  method_kind: :singleton
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: protected_singleton_method
  method_kind: :singleton
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: public_singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: protected_method
  method_kind: :instance
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Foo
    type: :class
    path: []
    generic_arguments: []
  method_name: public_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: protected_method
  method_kind: :instance
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: Object
    type: :class
    path: []
    generic_arguments: []
  method_name: public_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    type: :module
    path: []
    generic_arguments: []
  method_name: private_singleton_method
  method_kind: :singleton
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    type: :module
    path: []
    generic_arguments: []
  method_name: protected_singleton_method
  method_kind: :singleton
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::Constant
    name: A
    type: :module
    path: []
    generic_arguments: []
  method_name: public_singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::Constant
    name: NilClass
    type: :class
    path: []
    generic_arguments: []
  params: []
