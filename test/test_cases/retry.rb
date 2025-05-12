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
  method_owner: !ruby/object:Racer::Trace::ConstantInstance
    name: Object
    singleton: false
    generic_arguments: []
  method_name: foo
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
    name: PP::PPMethods
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PrettyPrint
    anonymous: false
    type: :class
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: PP
    anonymous: false
    type: :class
    superclass: PrettyPrint
    included_modules:
    - PP::PPMethods
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
    name: JSON
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator
    anonymous: false
    type: :module
    superclass:
    included_modules: []
    prepended_modules: []
    extended_modules: []
  - !ruby/object:Racer::Trace::Constant
    name: JSON::Ext::Generator::GeneratorMethods
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
    - PP::ObjectMixin
    - JSON::Ext::Generator::GeneratorMethods::Object
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
    name: Object
    singleton: false
    generic_arguments: []
  method_name: bar
  method_kind: :instance
  method_visibility: :private
  return_type: !ruby/object:Racer::Trace::ConstantInstance
    name: NilClass
    singleton: false
    generic_arguments: []
  params: []
  block_param: !ruby/object:Racer::Trace::BlockParam
    name: block
    traces:
    - !ruby/object:Racer::Trace::BlockTrace
      return_type: !ruby/object:Racer::Trace::ConstantInstance
        name: NilClass
        singleton: false
        generic_arguments: []
      params: []
      block_param:
      self_type: !ruby/object:Racer::Trace::ConstantInstance
        name: Object
        singleton: false
        generic_arguments: []
  constant_updates: []
