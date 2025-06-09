require "rbs"
require "fileutils"
require "yaml"

module Racer::Collectors
  class RBSCollector
    module EnsureValidConstantName
      def self.valid_name(name)
        return unless name

        name.split("::").map do |fragment|
          fragment[0].upcase.concat(fragment[1..])
        end.join("::")
      end

      def ensure_valid_name!
        return if defined?(@original_name)
        @original_name = @name
        @name = EnsureValidConstantName.valid_name(@name)
      end

      refine Racer::Trace::Constant do
        import_methods EnsureValidConstantName

        def ensure_valid_names!
          ensure_valid_name!

          @superclass = EnsureValidConstantName.valid_name(@superclass)
          @included_modules = @included_modules.map { EnsureValidConstantName.valid_name(_1) }
          @prepended_modules = @prepended_modules.map { EnsureValidConstantName.valid_name(_1) }
          @extended_modules = @extended_modules.map { EnsureValidConstantName.valid_name(_1) }
        end

        def set_superclass_alias!(alias_name)
          @original_superclass = @superclass
          @superclass = alias_name
        end
      end

      refine Racer::Trace::ConstantInstance do
        import_methods EnsureValidConstantName
      end
    end
    using EnsureValidConstantName

    module EnsureValidMethodName
      refine Racer::Trace do
        def valid_method_name?
          method_name.match?(
            /\A([a-zA-Z_][a-zA-Z0-9_]*[!?=]?|\+|\-|\*|\/|%|\*\*|==|!=|===|<=>|<=|>=|<|>|\<\<|\>\>|\&|\||\^|~|!|`|=~|!~|\[\]|\[\]=)\z/
          )
        end
      end
    end
    using EnsureValidMethodName

    def initialize(libraries: [])
      @results = {}

      loader = RBS::EnvironmentLoader.new
      libraries.each { loader.add(library: _1) }

      rbs_collection_config = Pathname.new("rbs_collection.yaml")
      if rbs_collection_config.exist?
        lockfile_path = RBS::Collection::Config.to_lockfile_path(rbs_collection_config)
        lockfile_content = YAML.load_file(lockfile_path)
        lockfile = RBS::Collection::Config::Lockfile.from_lockfile(lockfile_path:, data: lockfile_content)
        loader.add_collection(lockfile)
      end

      @environment = RBS::Environment.from_loader(loader).resolve_type_names
      @definition_builder = RBS::DefinitionBuilder.new(env: @environment)

      @existing_types = {}
      # Modules that are included or prepended to the Object class
      # need to have a self type that is not Object (for example BasicObject)
      @modules_in_object_class = Set.new
    end

    def collect(trace)
      trace.constant_updates.each do |constant|
        constant.ensure_valid_names!

        push_constant_to_results(constant)
      end

      unless trace.valid_method_name?
        return
      end

      method_type_key =
        case trace.method_kind
        when :instance
          :instance_methods
        when :singleton
          :singleton_methods
        end

      owner = trace.method_callee || trace.method_owner

      @results[owner.name][method_type_key][trace.method_name] ||= []

      @results[owner.name][method_type_key][trace.method_name].each do |traces|
        if traces.params == trace.params && traces.return_type == trace.return_type && traces.block_param == trace.block_param
          return
        end
      end

      @results[owner.name][method_type_key][trace.method_name] << trace
    end

    def stop(path: "sig/generated")
      FileUtils.rm_r(path) if File.directory?(path)
      @results.each do |owner_name, owner|

        owner => { constant:, instance_methods:, singleton_methods: }

        declarations =
          [
            case constant.type
            when :class
              to_class_declaration(constant, instance_methods, singleton_methods)
            when :module
              to_module_declaration(constant, instance_methods, singleton_methods)
            else
              puts "Unknown owner type #{type} (#{instance_methods}, #{singleton_methods})"
            end
          ].compact

        # Skip writing for invalid owners and if the owner has no members and already exists as RBS
        if declarations.empty? || (declarations.first.members.empty? && @existing_types.key?(owner_name))
          next
        end

        filename = "#{path}/#{owner_name.split("::").map { underscore(_1) }.join("/")}.rbs"
        dirname = File.dirname(filename)
        unless File.directory?(dirname)
          FileUtils.mkdir_p(dirname)
        end

        io = File.open(filename, "w")
        writer = RBS::Writer.new(out: io)
        writer.write(declarations)
        io.close
      end
    end

    private

    def underscore(camel_cased_word)
      return camel_cased_word.to_s.dup unless /[A-Z-]|::/.match?(camel_cased_word)
      word = camel_cased_word.to_s.gsub("::", "/")
      word.gsub!(/(?<=[A-Z])(?=[A-Z][a-z])|(?<=[a-z\d])(?=[A-Z])/, "_")
      word.tr!("-", "_")
      word.downcase!
      word
    end

    def push_constant_to_results(constant)
      return if @results.key?(constant.name)
      return if @existing_types.key?(constant.name)

      # TODO: Should we refactor this to store the relative name at the Constant class?
      # We also need the absolute path though to check in the maps above
      path = constant.name.split("::").map(&:to_sym)

      type_name =
        RBS::TypeName.new(
          name: path.pop,
          namespace: RBS::Namespace.new(path:, absolute: true)
        )

      class_decl = @environment.class_decls[type_name]
      if class_decl
        @existing_types[constant.name] = { class_decl:, type_name: }

        if constant.superclass && @results.key?(constant.superclass) && class_decl.primary.decl.super_class && constant.superclass != class_decl.primary.decl.super_class.name.to_s
          superclass_name = class_decl.primary.decl.super_class.name.to_s.delete_prefix("::")
          constant.set_superclass_alias!(superclass_name)
        end
      end

      if constant.name == "Object"
        constant.included_modules.each do |module_name|
          @modules_in_object_class.add(module_name)
        end

        constant.prepended_modules.each do |module_name|
          @modules_in_object_class.add(module_name)
        end
      end

      @results[constant.name] = { constant:, instance_methods: {}, singleton_methods: {} }
    end

    def to_module_declaration(owner, instance_methods, singleton_methods)
      self_types =
        if @modules_in_object_class.include?(owner.name)
          [RBS::AST::Declarations::Module::Self.new(name: to_type_name("BasicObject"), args: [], location: nil)]
        else
          []
        end

      RBS::AST::Declarations::Module.new(
        name: to_type_name(owner.name),
        type_params: type_params_of_existing_class(owner.name),
        members: to_module_members(owner, instance_methods, singleton_methods),
        annotations: [],
        self_types:,
        location: nil,
        comment: nil
      )
    end

    def to_class_declaration(owner, instance_methods, singleton_methods)
      super_class =
        if owner.superclass
          RBS::AST::Declarations::Class::Super.new(
            name: to_type_name(owner.superclass),
            args: generic_arguments_of_class(owner.superclass),
            location: nil
          )
        end

      RBS::AST::Declarations::Class.new(
        name: to_type_name(owner.name),
        type_params: type_params_of_existing_class(owner.name),
        super_class:,
        members: to_module_members(owner, instance_methods, singleton_methods),
        annotations: [],
        location: nil,
        comment: nil
      )
    end

    def to_module_members(constant, instance_methods, singleton_methods)
      [
        *to_mixin_definitions(constant.extended_modules, :extend),
        *to_mixin_definitions(constant.prepended_modules, :prepend),
        *to_mixin_definitions(constant.included_modules, :include),
        *to_method_definitions(instance_methods, singleton_methods),
        *required_interface_definitions(constant, instance_methods, singleton_methods)
      ]
    end

    def required_interface_definitions(constant, instance_methods, singleton_methods)
      required_interface_members = ->(modules, existing_methods, kind) do
        needed_methods = {}

        existing_type = @existing_types[constant.name]

        instance =
          if existing_type
            case kind
            when :instance
              @definition_builder.build_instance(existing_type[:type_name])
            when :singleton
              @definition_builder.build_singleton(existing_type[:type_name])
            end
          end

        modules.each do |module_name|
          module_existing_type = @existing_types[module_name]
          next unless module_existing_type

          type_name = module_existing_type[:type_name]

          ancestors = @definition_builder.ancestor_builder.one_instance_ancestors(type_name)
          ancestors.each_self_type do |self_type|
            next unless @environment.interface_name?(self_type.name)

            interface_definition = @definition_builder.build_interface(self_type.name)
            needed_methods.merge!(interface_definition.methods)
          end
        end

        needed_methods.filter_map do |name, definition|
          next if existing_methods.key?(name.to_s)
          next if instance && instance.methods[name]&.implemented_in

          defined_member = definition.defs.first.member
          overload = defined_member.overloads.first
          method_type = overload.method_type.map_type { RBS::Types::Bases::Any.new(location: nil) }

          defined_member.update(kind:, overloads: [overload.update(method_type:)])
        end
      end

      [
        *required_interface_members.([*constant.prepended_modules, *constant.included_modules], instance_methods, :instance),
        *required_interface_members.(constant.extended_modules, singleton_methods, :singleton)
      ]
    end

    def to_method_definitions(instance_methods, singleton_methods)
      instance_methods.map do |name, overloads|
        to_method_definition(name, :instance, overloads)
      end.concat(
        singleton_methods.map do |name, overloads|
          to_method_definition(name, :singleton, overloads)
        end
      ).compact
    end

    def method_defined?(method_name, method_kind, owner_name)
      existing_type = @existing_types[owner_name]

      if existing_type
        methods =
          case method_kind
          when :instance
            existing_type[:instance] ||= @definition_builder.build_instance(existing_type[:type_name])
          when :singleton
            existing_type[:singleton] ||= @definition_builder.build_singleton(existing_type[:type_name])
          end.methods

        methods.key?(method_name.to_sym)
      else
        false
      end
    end

    def to_method_definition(name, kind, traces)
      first_trace = traces.first

      # This is not ideal as we miss redefined core methods (for example if redefining Integer#+).
      # Howver in most cases this does not happend and we instead want to keep the original type definition to have more
      # correct signatures (for example Object#tap returns self instead of a chain of union types).
      return if method_defined?(name, kind, first_trace.method_owner.name)

      # We add methods to the method callee if present. In this case we still check if the callee
      # defines this method already. As the callee is not equal to the owner, the method signature might
      # have changed from the implemented method on the callee, so we overload in this case.
      overloading =
        if first_trace.method_callee
          method_defined?(name, kind, first_trace.method_callee.name)
        else
          false
        end

      # It could totally be that a method was public when called the first time and private
      # the next time. We cannot depict such a case using RBS.
      visibility = traces.last.method_visibility

      overloads = {}

      traces.map do |trace|
        key = [trace.params]
        if trace.block_param
          params = trace.block_param.traces.first&.params || []
          key << params.map { [_1.name, _1.type] }
        end

        overloads[key] ||= []
        overloads[key] << trace
      end

      return_type =
        if name == "initialize"
          RBS::Types::Bases::Void.new(location: nil)
        end

      RBS::AST::Members::MethodDefinition.new(
        name: name.to_sym,
        kind:,
        overloads: overloads.map do |(params, *), overload_traces|
          block_params = overload_traces.filter_map(&:block_param)

          unless block_params.empty?
            block_traces = block_params.flat_map(&:traces)
            param_sets = block_traces.map(&:params)
            unless param_sets.empty?
              size = param_sets.first.size
              if param_sets.any? { _1.size != size }
                warn "block params different for #{overload_traces}"
              end
            end
          end

          RBS::AST::Members::MethodDefinition::Overload.new(
            method_type: RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.new(
                **method_parameters(params),
                return_type: return_type || to_rbs_type(*overload_traces.map(&:return_type))
              ),
              block: block_params.empty? ? nil : to_block(block_params),
              location: nil
            ),
            annotations: []
          )
        end,
        annotations: [],
        overloading:,
        location: nil,
        comment: nil,
        # We do not use visibility sections so declare all methods that are not private
        # without visibility to mark them as "public".
        # Protected methods are not supported by RBS yet.
        visibility: visibility == :private ? :private : nil
      )
    end

    def method_parameters(*param_sets)
      {
        required_positionals: [],
        optional_positionals: [],
        trailing_positionals: [],
        rest_positionals: nil,
        required_keywords: {},
        optional_keywords: {},
        rest_keywords: nil
      }.tap do |parameters|
        size = param_sets.first.size
        if param_sets.any? { _1.size != size }
          warn "Received param sets with different sizes #{param_sets}"
          next
        end

        size.times do |n|
          # TODO-Racer: Rethink the data structure here...
          type = param_sets.first[n].type
          name = param_sets.first[n].name
          types = param_sets.map { _1[n].type_name }
          generic_arguments = types.first.generic_arguments

          case type
          when :required, :optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_rbs_type(*types),
                name:
              )

            if type == :required
              if parameters[:rest_positionals]
                parameters[:trailing_positionals] << rbs_param
              else
                parameters[:required_positionals] << rbs_param
              end
            else
              parameters[:optional_positionals] << rbs_param
            end
          when :rest
            type =
              if generic_arguments.size == 1
                to_rbs_type(*generic_arguments[0])
              else
                RBS::Types::Bases::Any.new(location: nil)
              end

            parameters[:rest_positionals] =
              RBS::Types::Function::Param.new(
                type:,
                name: name == :* ? nil : name
              )
          when :keyword_required, :keyword_optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_rbs_type(*types),
                name: nil
              )

            if type == :keyword_required
              parameters[:required_keywords][name] = rbs_param
            else
              parameters[:optional_keywords][name] = rbs_param
            end
          when :keyword_rest
            type =
              if generic_arguments.size == 2
                to_rbs_type(*generic_arguments[1])
              else
                RBS::Types::Bases::Any.new(location: nil)
              end

            parameters[:rest_keywords] =
              RBS::Types::Function::Param.new(
                type:,
                name: name == :** ? nil : name
              )
          end
        end
      end
    end

    # Converts block parameters of a method to a block type
    # Note: RBS does not support blocks that get other blocks passed so we cannot document
    # "nested" block params.
    def to_block(block_params)
      required = block_params.any? { !_1.traces.empty? }

      traces = block_params.flat_map(&:traces)

      function =
        if traces.empty?
          RBS::Types::UntypedFunction.new(return_type: RBS::Types::Bases::Any.new(location: nil))
        else
          RBS::Types::Function.new(
            **method_parameters(*traces.map(&:params)),
            return_type: to_rbs_type(*traces.map(&:return_type))
          )
        end

      self_types = traces.filter_map(&:self_type)

      RBS::Types::Block.new(
        type: function,
        self_type: self_types.empty? ? nil : to_rbs_type(*self_types),
        required:
      )
    end

    def to_mixin_definitions(modules, type)
      klass =
        case type
        when :extend
          RBS::AST::Members::Extend
        when :prepend
          RBS::AST::Members::Prepend
        when :include
          RBS::AST::Members::Include
        end

      modules.map do |module_name|
        klass.new(
          name: to_type_name(module_name),
          args: generic_arguments_of_class(module_name),
          annotations: [],
          location: nil,
          comment: nil
        )
      end
    end

    def to_type_name(type_name_str)
      RBS::TypeName.new(name: type_name_str.to_sym, namespace: RBS::Namespace.root)
    end

    def to_rbs_type(*constants)
      constants.uniq!

      has_boolean = false
      constants.each do |constant|
        if constant.name == "TrueClass" || constant.name == "FalseClass"
          has_boolean = true
        end
      end

      if has_boolean
        constants.delete_if { _1.name == "TrueClass" || _1.name == "FalseClass" }
        constants.push(Racer::Trace::ConstantInstance.new(name: "bool", singleton: false, generic_arguments: []))
      end

      if constants.size > 1
        return RBS::Types::Union.new(types: constants.map { |type| to_rbs_type(type) }, location: nil)
      end

      constant = constants.first

      case constant.name
      when "bool"
        RBS::Types::Bases::Bool.new(location: nil)
      when "NilClass"
        RBS::Types::Bases::Nil.new(location: nil)
      else
        constant.ensure_valid_name!
        type_name = to_type_name(constant.name)

        if constant.singleton
          RBS::Types::ClassSingleton.new(
            name: type_name,
            location: nil
          )
        else
          RBS::Types::ClassInstance.new(
            name: type_name,
            args: generic_arguments_of_class(constant.name, constant.generic_arguments),
            location: nil
          )
        end
      end
    end

    def generic_arguments_of_class(name, existing_generic_arguments = [])
      return [] unless @existing_types.key?(name)

      existing_type = @existing_types[name][:class_decl]
      type_params = existing_type&.type_params || []

      if existing_generic_arguments.size == type_params.size
        existing_generic_arguments.map do |union_types|
          to_rbs_type(*union_types)
        end
      else
        type_params.map { |param| RBS::Types::Bases::Any.new(location: nil) }
      end
    end

    def type_params_of_existing_class(owner)
      return [] unless @existing_types.key?(owner)

      @existing_types[owner][:class_decl].type_params
    end
  end
end
