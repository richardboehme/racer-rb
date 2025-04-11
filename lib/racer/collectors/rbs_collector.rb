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
        if traces.params == trace.params
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
          end
        end

      writer.write(declarations.compact)
      io.close
    end

    private

    def to_class_delaration(owner, methods)
      method_definitions =
        methods.map do |name, overloads|
          RBS::AST::Members::MethodDefinition.new(
            name: name.to_sym,
            kind: :instance,
            overloads: overloads.map do |overload_trace|
              RBS::AST::Members::MethodDefinition::Overload.new(
                method_type: RBS::MethodType.new(
                  type_params: [],
                  type: RBS::Types::Function.new(
                    required_positionals: overload_trace.params.map do |(name, type)|
                      RBS::Types::Function::Param.new(
                        type:,
                        name:
                      )
                    end,
                    optional_positionals: [],
                    trailing_positionals: [],
                    required_keywords: {},
                    optional_keywords: {},
                    rest_positionals: nil,
                    rest_keywords: nil,
                    return_type: RBS::Types::Bases::Any.new(location: nil)
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

      RBS::AST::Declarations::Class.new(
        name: RBS::TypeName.new(name: owner, namespace: RBS::Namespace.new(path: [], absolute: true)),
        type_params: [],
        super_class: nil,
        members: method_definitions,
        annotations: [],
        location: nil,
        comment: nil
      )
    end
  end
end
