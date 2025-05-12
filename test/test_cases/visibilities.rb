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
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: private_singleton_method
  method_kind: :singleton
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: Foo
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::NilClass
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: NilClass
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - JSON::Ext::Generator::GeneratorMethods::NilClass
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: protected_singleton_method
  method_kind: :singleton
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: public_singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: protected_method
  method_kind: :instance
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Foo
    singleton: false
    generic_arguments: []
  method_name: public_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: private_method
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: A
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PP::ObjectMixin
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods::Object
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: Object
    anonymous: false
    type: :class
    superclass:
    included_modules:
    - A
    - PP::ObjectMixin
    - JSON::Ext::Generator::GeneratorMethods::Object
    prepended_modules: []
    extended_modules: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: protected_method
  method_kind: :instance
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: public_method
  method_kind: :instance
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: private_singleton_method
  method_kind: :singleton
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: protected_singleton_method
  method_kind: :singleton
  method_visibility: :protected
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
- !ruby/object:Racer::Trace
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: A
    singleton: false
    generic_arguments: []
  method_name: public_singleton_method
  method_kind: :singleton
  method_visibility: :public
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param:
  constant_updates: []
