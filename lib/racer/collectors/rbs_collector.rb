require "rbs"

module Racer::Collectors
  class RBSCollector
    def initialize
      @results = {}
      loader = RBS::EnvironmentLoader.new
      @environment = RBS::Environment.from_loader(loader).resolve_type_names
      @definition_builder = RBS::DefinitionBuilder.new(env: @environment)
      @existing_types = {}
    end

    def collect(trace)
      trace.constant_updates.each do |constant|
        push_constant_to_results(constant)
      end

      method_type_key =
        case trace.method_kind
        when :instance
          :instance_methods
        when :singleton
          :singleton_methods
        end

      @results[trace.method_owner.name][method_type_key][trace.method_name] ||= []

      @results[trace.method_owner.name][method_type_key][trace.method_name].each do |traces|
        if traces.params == trace.params && traces.return_type == trace.return_type && traces.block_param == trace.block_param
          return
        end
      end

      @results[trace.method_owner.name][method_type_key][trace.method_name] << trace
    end

    def stop(path: "output.rbs")
      io = File.open(path, "w")
      writer = RBS::Writer.new(out: io)

      declarations =
        @results.map do |owner_name, owner|
          owner => { constant:, instance_methods:, singleton_methods: }

          case constant.type
          when :class
            to_class_delaration(constant, instance_methods, singleton_methods)
          when :module
            to_module_declaration(constant, instance_methods, singleton_methods)
          else
            puts "Unknown owner type #{type} (#{instance_methods}, #{singleton_methods})"
          end
        end

      writer.write(declarations.compact)
      io.close
    end

    private

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
      end

      @results[constant.name] = { constant:, instance_methods: {}, singleton_methods: {} }
    end

    def to_module_declaration(owner, instance_methods, singleton_methods)
      RBS::AST::Declarations::Module.new(
        name: to_type_name(owner.name),
        type_params: type_params_of_existing_class(owner.name),
        members: to_module_members(owner, instance_methods, singleton_methods),
        annotations: [],
        self_types: [],
        location: nil,
        comment: nil
      )
    end

    def to_class_delaration(owner, instance_methods, singleton_methods)
      super_class =
        if owner.superclass
          RBS::AST::Declarations::Class::Super.new(
            name: to_type_name(owner.superclass),
            args: type_params_of_existing_class(owner.superclass),
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
        *to_method_definitions(instance_methods, singleton_methods)
      ]
    end

    def to_method_definitions(instance_methods, singleton_methods)
      instance_methods.map do |name, overloads|
        to_method_definition(name, :instance, overloads)
      end.concat(
        singleton_methods.map do |name, overloads|
          to_method_definition(name, :singleton, overloads)
        end
      )
    end

    def to_method_definition(name, kind, traces)
      # It could totally be that a method was public when called the first time and private
      # the next time. We cannot depict such a case using RBS.
      visibility = traces.last.method_visibility

      overloads = {}

      traces.map do |trace|
        overloads[trace.params] ||= []
        overloads[trace.params] << trace
      end

      existing_type = @existing_types[traces.first.method_owner.name]
      overloading =
        if existing_type
          methods =
            case kind
            when :instance
              existing_type[:instance] ||= @definition_builder.build_instance(existing_type[:type_name])
            when :singleton
              existing_type[:singleton] ||= @definition_builder.build_singleton(existing_type[:type_name])
            end.methods

          methods.key?(name.to_sym)
        end

      return_type =
        if name == "initialize"
          RBS::Types::Bases::Void.new(location: nil)
        end

      RBS::AST::Members::MethodDefinition.new(
        name: name.to_sym,
        kind:,
        overloads: overloads.map do |params, traces|
          block_params = traces.filter_map(&:block_param)

          RBS::AST::Members::MethodDefinition::Overload.new(
            method_type: RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.new(
                **method_parameters(params),
                return_type: return_type || to_rbs_type(*traces.map(&:return_type))
              ),
              block: block_params.empty? ? nil : to_block(block_params),
              location: nil
            ),
            annotations: []
          )
        end,
        annotations: [],
        overloading: !!overloading,
        location: nil,
        comment: nil,
        # We do not use visibility sections so declare all methods that are not private
        # without visibility to mark them as "public".
        # Protected methods are not supported by RBS yet.
        visibility: visibility == :private ? :private : nil
      )
    end

    def method_parameters(*param_sets)
      size = param_sets.first.size
      if param_sets.any? { it.size != size }
        warn "Received param sets with different sizes"
      end

      {
        required_positionals: [],
        optional_positionals: [],
        trailing_positionals: [],
        rest_positionals: nil,
        required_keywords: {},
        optional_keywords: {},
        rest_keywords: nil
      }.tap do |parameters|
        size.times do |n|
          # TODO-Racer: Rethink the data structure here...
          type = param_sets.first[n].type
          name = param_sets.first[n].name
          types = param_sets.map { it[n].type_name }
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
      required = block_params.any? { !it.traces.empty? }

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
          args: type_params_of_existing_class(module_name),
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
        constants.delete_if { it.name == "TrueClass" || it.name == "FalseClass" }
        constants.push(Racer::Trace::Constant.new(name: "bool", anonymous: false, type: :class))
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
        type_name = to_type_name(constant.name)

        if constant.singleton
          RBS::Types::ClassSingleton.new(
            name: type_name,
            location: nil
          )
        else
          existing_type = @environment.class_decls[type_name]
          type_params = existing_type&.type_params || []

          args =
            if constant.generic_arguments.size == type_params.size
              constant.generic_arguments.map do |union_types|
                to_rbs_type(*union_types)
              end
            else
              type_params.map { |param| RBS::Types::Bases::Any.new(location: nil) }
            end


          RBS::Types::ClassInstance.new(
            name: type_name,
            args:,
            location: nil
          )
        end
      end
    end

    def type_params_of_existing_class(owner)
      return [] unless @existing_types.key?(owner)

      @existing_types[owner][:class_decl].type_params
    end
  end
end
