require "rbs"

module Racer::Collectors
  class RBSCollector
    def initialize
      @results = {}
      loader = RBS::EnvironmentLoader.new
      @environment = RBS::Environment.from_loader(loader).resolve_type_names
      @definition_builder = RBS::DefinitionBuilder.new(env: @environment)
      @has_types = Set.new
    end

    def collect(trace)
      push_constant_to_results(trace.method_owner)

      # TODO: We probably want to "enhance" those types (say monkey patches) but we'd at least need to copy their type params (generics)
      return if @has_types.include?(trace.method_owner.name)

      method_type_key =
        case trace.method_kind
        in :instance
          :instance_methods
        in :singleton
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
    end

    def push_type_to_results(name, class_type, path)
      return if @results.key?(name)
      return if @has_types.include?(name)

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

      if @environment.class_decls.key?(type_name)
        @has_types.add(name)
        return
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
        type_params: [],
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

    def to_method_definition(name, kind, overloads)
      RBS::AST::Members::MethodDefinition.new(
        name: name.to_sym,
        kind:,
        overloads: overloads.map do |overload_trace|
          RBS::AST::Members::MethodDefinition::Overload.new(
            method_type: RBS::MethodType.new(
              type_params: [],
              type: RBS::Types::Function.new(
                **method_parameters(overload_trace.params),
                return_type: to_class_instance_type(overload_trace.return_type.name)
              ),
              block: nil,
              location: nil
            ),
            annotations: []
          )
        end,
        annotations: [],
        overloading: false,
        location: nil,
        comment: nil,
        visibility: nil
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
                type: to_class_instance_type(param.type_name.name),
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
            type = param.type_name.name

            parameters[:rest_positionals] =
              RBS::Types::Function::Param.new(
                type: to_class_instance_type(type),
                name: param.name == :* ? nil : param.name
              )
          when :keyword_required, :keyword_optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_class_instance_type(param.type_name.name),
                name: nil
              )

            if param.type == :keyword_required
              parameters[:required_keywords][param.name] = rbs_param
            else
              parameters[:optional_keywords][param.name] = rbs_param
            end
          when :keyword_rest
            type = param.type_name.name

            parameters[:rest_keywords] =
              RBS::Types::Function::Param.new(
                type: to_class_instance_type(type),
                name: param.name == :** ? nil : param.name
              )
          end
        end
      end
    end

    def to_type_name(type_name_str)
      RBS::TypeName.new(name: type_name_str.to_sym, namespace: RBS::Namespace.root)
    end

    def to_class_instance_type(type_name_str)
      type_name = to_type_name(type_name_str)
      existing_type = @environment.class_decls[type_name]
      type_params = existing_type&.type_params || []

      RBS::Types::ClassInstance.new(
        name: type_name,
        args: type_params.map { |param| RBS::Types::Bases::Any.new(location: nil) },
        location: nil
      )
    end
  end
end
