require 'rbs'

module Racer::Collectors
  class RBSCollector
    def initialize
      @io = File.open('output.rbs', 'w')
      @writer = RBS::Writer.new(out: @io)
    end

    def collect(trace)
      case trace.method_owner_type
      when "Class"
        write_class_declaration(trace)
      when "Module"
        #write_module_declaration(trace)
      end
    end

    def stop
      @io.close
    end

    private

    def write_class_declaration(trace)
      declaration =
        RBS::AST::Declarations::Class.new(
          name: RBS::TypeName.new(name: trace.method_owner, namespace: RBS::Namespace.new(path: [], absolute: true)),
          type_params: [],
          super_class: nil,
          members: [],
          annotations: [],
          location: nil,
          comment: nil
        )
      @writer.write([declaration])
    end
  end
end


# Issues:
# * it seems to be slow as fuck (tried with cleverhandwerk test suite) or there is something broken maybe
# * there is still a bug with params fetching in cleverhandwerk, maybe tp_params still does not work as intended?
