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
  block_param:
  constant_updates:
  - !ruby/object:Racer::Trace::Constant
    name: Object
    anonymous: true
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
