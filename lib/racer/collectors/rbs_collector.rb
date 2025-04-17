require "rbs"

module Racer::Collectors
  class RBSCollector
    def initialize
      @results = {}
      loader = RBS::EnvironmentLoader.new
      @environment = RBS::Environment.from_loader(loader).resolve_type_names
      @has_types = Set.new
    end

    def collect(trace)
      return if @has_types.include?(trace.method_owner)

      # TODO: We probably want to "enhance" those types but we'd at least need to copy their type params (generics)
      type = RBS::TypeName.new(name: trace.method_owner.to_sym, namespace: RBS::Namespace.root)
      if @environment.class_decls.key?(type)
        @has_types.add(trace.method_owner)
        return
      end

      @results[trace.method_owner] ||= {}
      @results[trace.method_owner][trace.method_name] ||= []

      @results[trace.method_owner][trace.method_name].each do |traces|
        if traces.params == trace.params && traces.return_type == trace.return_type
          return
        end
      end

      @results[trace.method_owner][trace.method_name] << trace
    end

    def stop
      io = File.open("output.rbs", "w")
      writer = RBS::Writer.new(out: io)

      declarations =
        @results.map do |owner, methods|
          next if methods.empty?

          type = methods.first[1].first.method_owner_type

          case type
          when "Class"
            to_class_delaration(owner, methods)
          when "Module"
            to_module_declaration(owner, methods)
          else
            puts "Unknown owner type #{type} (#{methods})"
          end
        end

      writer.write(declarations.compact)
      io.close
    end

    private

    def to_module_declaration(owner, methods)
      RBS::AST::Declarations::Module.new(
        name: to_type_name(owner),
        type_params: [],
        members: to_method_definitions(methods),
        annotations: [],
        self_types: [],
        location: nil,
        comment: nil
      )
    end

    def to_class_delaration(owner, methods)
      RBS::AST::Declarations::Class.new(
        name: to_type_name(owner),
        type_params: [],
        super_class: nil,
        members: to_method_definitions(methods),
        annotations: [],
        location: nil,
        comment: nil
      )
    end

    def to_method_definitions(methods)
      methods.map do |name, overloads|
        RBS::AST::Members::MethodDefinition.new(
          name: name.to_sym,
          kind: :instance,
          overloads: overloads.map do |overload_trace|
            RBS::AST::Members::MethodDefinition::Overload.new(
              method_type: RBS::MethodType.new(
                type_params: [],
                type: RBS::Types::Function.new(
                  **method_parameters(overload_trace.params),
                  rest_positionals: nil,
                  return_type: RBS::Types::ClassInstance.new(name: to_type_name(overload_trace.return_type), args: [], location: nil)
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
    end

    def method_parameters(params)
      {
        required_positionals: [],
        optional_positionals: [],
        trailing_positionals: [],
        required_keywords: {},
        optional_keywords: {},
        rest_keywords: nil
      }.tap do |parameters|
        params.each do |param|
          case param.type
          when :required, :optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_type_name(param.class_name),
                name: param.name
              )

            if param.type == :required
              parameters[:required_positionals] << rbs_param
            else
              parameters[:optional_positionals] << rbs_param
            end
          when :keyword_required, :keyword_optional
            rbs_param =
              RBS::Types::Function::Param.new(
                type: to_type_name(param.class_name),
                name: nil
              )

            if param.type == :keyword_required
              parameters[:required_keywords][param.name] = rbs_param
            else
              parameters[:optional_keywords][param.name] = rbs_param
            end
          when :keyword_rest
            type =
              if param.class_name == "(null)"
                if param.name == :**
                  "Hash"
                else
                  ""
                end
              else
                param.class_name
              end

            parameters[:rest_keywords] =
              RBS::Types::Function::Param.new(
                type: to_type_name(type),
                name: param.name == :** ? nil : param.name
              )
          end
        end
      end
    end

    def to_type_name(type_name_str)
      RBS::TypeName.new(name: type_name_str.to_sym, namespace: RBS::Namespace.root)
    end
  end
end
