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
      push_constant_to_results(trace.method_owner)

      method_type_key =
        case trace.method_kind
        when :instance
          :instance_methods
        when :singleton
          :singleton_methods
        end

      @results[trace.method_owner.name][method_type_key][trace.method_name] ||= []

      @results[trace.method_owner.name][method_type_key][trace.method_name].each do |traces|
        if traces.params == trace.params && traces.return_type == trace.return_type
          return
        end
      end

      push_constant_to_results(trace.return_type)

      trace.params.each do |param|
        push_constant_to_results(param.type_name)
      end

      @results[trace.method_owner.name][method_type_key][trace.method_name] << trace
    end

    def stop(path: "output.rbs")
      io = File.open(path, "w")
      writer = RBS::Writer.new(out: io)

      declarations =
        @results.map do |owner_name, owner|
          owner => { type:, instance_methods:, singleton_methods: }

          next if instance_methods.empty? && singleton_methods.empty? && @existing_types.key?(owner_name)

          case type
          when :class
            to_class_delaration(owner_name, instance_methods, singleton_methods)
          when :module
            to_module_declaration(owner_name, instance_methods, singleton_methods)
          else
            puts "Unknown owner type #{type} (#{instance_methods}, #{singleton_methods})"
          end
        end

      writer.write(declarations.compact)
      io.close
    end

    private

    def push_constant_to_results(constant)
      path = constant.path.dup
      push_type_to_results(constant.name, constant.type, path.map(&:name))

      until path.empty?
        absolute_name = path.map(&:name).join("::")
        fragment = path.pop

        push_type_to_results(absolute_name, fragment.type, path.map(&:name))
      end

      constant.generic_arguments.each do |argument|
        argument.each do |type|
          push_constant_to_results(type)
        end
      end
    end

    def push_type_to_results(name, class_type, path)
      return if @results.key?(name)
      return if @existing_types.key?(name)

      # TODO: Should we refactor this to store the relative name at the Constant class?
      # We also need the absolute path though to check in the maps above
      start_index = name.rindex(":")
      if start_index.nil?
        start_index = 0
      else
        start_index += 1
      end

      relative_name = name[start_index..]
      type_name =
        RBS::TypeName.new(
          name: relative_name.to_sym,
          namespace: RBS::Namespace.new(path:, absolute: true)
        )

      class_decl = @environment.class_decls[type_name]
      if class_decl
        @existing_types[name] = { class_decl:, type_name: }
      end

      @results[name] = { type: class_type, instance_methods: {}, singleton_methods: {} }
    end

    def to_module_declaration(owner, instance_methods, singleton_methods)
      RBS::AST::Declarations::Module.new(
        name: to_type_name(owner),
        type_params: [],
        members: to_method_definitions(instance_methods, singleton_methods),
        annotations: [],
        self_types: [],
        location: nil,
        comment: nil
      )
    end

    def to_class_delaration(owner, instance_methods, singleton_methods)
      RBS::AST::Declarations::Class.new(
        name: to_type_name(owner),
        type_params: type_params_of_existing_class(owner),
        super_class: nil,
        members: to_method_definitions(instance_methods, singleton_methods),
        annotations: [],
        location: nil,
        comment: nil
      )
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

      RBS::AST::Members::MethodDefinition.new(
        name: name.to_sym,
        kind:,
        overloads: overloads.map do |params, traces|
          block_params = traces.flat_map(&:params).select { it.type == :block }

          RBS::AST::Members::MethodDefinition::Overload.new(
            method_type: RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.new(
                **method_parameters(params),
                return_type: to_rbs_type(*traces.map(&:return_type).uniq)
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

    def method_parameters(params)
      {
        required_positionals: [],
        optional_positionals: [],
        trailing_positionals: [],
        rest_positionals: nil,
        required_keywords: {},
        optional_keywords: {},
        rest_keywords: nil
      }.tap do |parameters|
        params.each do |param|
          case param.type
          when :required, :optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_rbs_type(param.type_name),
                name: param.name
              )

            if param.type == :required
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
              if param.type_name.generic_arguments.size == 1
                to_rbs_type(*param.type_name.generic_arguments[0])
              else
                RBS::Types::Bases::Any.new(location: nil)
              end

            parameters[:rest_positionals] =
              RBS::Types::Function::Param.new(
                type:,
                name: param.name == :* ? nil : param.name
              )
          when :keyword_required, :keyword_optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_rbs_type(param.type_name),
                name: nil
              )

            if param.type == :keyword_required
              parameters[:required_keywords][param.name] = rbs_param
            else
              parameters[:optional_keywords][param.name] = rbs_param
            end
          when :keyword_rest
            type =
              if param.type_name.generic_arguments.size == 2
                to_rbs_type(*param.type_name.generic_arguments[1])
              else
                RBS::Types::Bases::Any.new(location: nil)
              end

            parameters[:rest_keywords] =
              RBS::Types::Function::Param.new(
                type:,
                name: param.name == :** ? nil : param.name
              )
          end
        end
      end
    end

    def to_block(block_params)
      required = block_params.none? { it.type_name.name == "NilClass" }

      RBS::Types::Block.new(
        type: RBS::Types::UntypedFunction.new(return_type: RBS::Types::Bases::Any.new(location: nil)),
        required:
      )
    end

    def to_type_name(type_name_str)
      RBS::TypeName.new(name: type_name_str.to_sym, namespace: RBS::Namespace.root)
    end

    def to_rbs_type(*constants)
      if constants.size > 1
        bool_union = [false, false]
        constants.each do |constant|
          if constant.name == "TrueClass"
            bool_union[0] = true
          elsif constant.name == "FalseClass"
            bool_union[1] = true
          end
        end

        if bool_union.all?
          constants.delete_if { it.name == "TrueClass" || it.name == "FalseClass" }
          constants.push(Racer::Trace::Constant.new(name: "bool", type: :class, path: [], generic_arguments: []))
        end
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
      when "TrueClass"
        RBS::Types::Literal.new(literal: true, location: nil)
      when "FalseClass"
        RBS::Types::Literal.new(literal: false, location: nil)
      else
        type_name = to_type_name(constant.name)
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

    def type_params_of_existing_class(owner)
      return [] unless @existing_types.key?(owner)

      @existing_types[owner][:class_decl].type_params
    end
  end
end
