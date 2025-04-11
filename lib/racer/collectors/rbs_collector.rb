require "rbs"

module Racer::Collectors
  class RBSCollector
    def initialize
      @results = {}
    end

    def collect(trace)
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
            puts "Unknown owner type #{type}"
          end
        end

      writer.write(declarations.compact)
      io.close
    end

    private

    def to_module_declaration(owner, methods)
      RBS::AST::Declarations::Module.new(
        name: RBS::TypeName.new(name: owner, namespace: RBS::Namespace.new(path: [], absolute: true)),
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
        name: RBS::TypeName.new(name: owner, namespace: RBS::Namespace.new(path: [], absolute: true)),
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
                  return_type: RBS::Types::ClassInstance.new(name: overload_trace.return_type, args: [], location: nil)
                ),
                block: nil,
                location: nil
              ),
              annotations: []
            )
          end,
          annotations: [],
          overloading: true,
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
                type: param.class_name,
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
                type: param.class_name,
                name: nil
              )

            if param.type == :keyword_required
              parameters[:required_keywords][param.name] = rbs_param
            else
              parameters[:optional_keywords][param.name] = rbs_param
            end
          when :keyword_rest
            parameters[:rest_keywords] =
              RBS::Types::Function::Param.new(
                type: param.class_name == "(null)" ? "" : param.class_name,
                name: param.name == :** ? nil : param.name
              )
          end
        end
      end
    end
  end
end
