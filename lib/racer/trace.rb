class Racer::Trace
  attr_reader :method_owner, :method_name, :method_kind, :method_visibility, :return_type, :params, :block_param

  KINDS = [
    :instance,
    :singleton
  ].freeze

  VISIBILITIES = [
    :public,
    :private,
    :protected
  ].freeze

  def initialize(method_owner:, method_name:, method_kind:, method_visibility:, return_type:, params:, block_param: nil)
    @method_owner = method_owner
    @method_name = method_name
    @method_kind = method_kind
    @method_visibility = method_visibility
    @return_type = return_type
    @params = params
    @block_param = block_param
  end

  class Constant
    attr_reader :name, :singleton, :type, :path, :generic_arguments

    TYPES = [
      :module,
      :class
    ].freeze

    def initialize(name:, singleton:, type:, path:, generic_arguments: [])
      @name = name
      @singleton = singleton
      @type = type
      @path = path
      @generic_arguments = generic_arguments
    end

    class PathFragment
      attr_reader :name, :type

      def initialize(name:, type:)
        @name = name
        @type = type
      end
    end

    def ==(other)
      other.name == name && generic_arguments == other.generic_arguments
    end
    alias eql? ==

    def hash
      [name, generic_arguments].hash
    end
  end

  class Param
    attr_reader :name, :type_name, :type

    TYPES = [
      :required,
      :optional,
      :rest,
      :keyword_required,
      :keyword_optional,
      :keyword_rest
    ].freeze


    def initialize(name:, type_name:, type:)
      @name = name
      @type_name = type_name
      @type = type
    end

    def ==(other)
      other.name == name && other.type_name == type_name && other.type == type
    end
    alias eql? ==

    def hash
      [name, type_name, type].hash
    end
  end

  class BlockParam
    attr_reader :name, :traces

    def initialize(name:, traces:)
      @name = name
      @traces = traces
    end
  end

  class BlockTrace
    attr_reader :self_type, :return_type, :params, :block_param

    def initialize(return_type:, params:, self_type: nil, block_param: nil)
      @return_type = return_type
      @params = params
      @block_param = block_param
      @self_type = self_type
    end
  end
end
