class Racer::Trace
  attr_reader :method_owner, :method_name, :method_kind, :method_visibility, :return_type, :params, :block_param, :constant_updates

  KINDS = [
    :instance,
    :singleton
  ].freeze

  VISIBILITIES = [
    :public,
    :private,
    :protected
  ].freeze

  def initialize(method_owner:, method_name:, method_kind:, method_visibility:, return_type:, params:, constant_updates: [], block_param: nil)
    @method_owner = method_owner
    @method_name = method_name
    @method_kind = method_kind
    @method_visibility = method_visibility
    @return_type = return_type
    @params = params
    @block_param = block_param
    @constant_updates = constant_updates
  end

  class Constant
    attr_reader :name, :anonymous, :type, :superclass, :included_modules, :prepended_modules, :extended_modules

    TYPES = [
      :module,
      :class
    ].freeze

    def initialize(name:, anonymous:, type:, superclass: nil, included_modules: [], prepended_modules: [], extended_modules: [])
      @name = name
      @anonymous = anonymous
      @type = type
      @superclass = superclass
      @included_modules = included_modules
      @prepended_modules = prepended_modules
      @extended_modules = extended_modules
    end
  end

  class ConstantInstance
    attr_reader :name, :singleton, :generic_arguments

    def initialize(name:, singleton:, generic_arguments:)
      @name = name
      @singleton = singleton
      @generic_arguments = generic_arguments
    end

    def ==(other)
      other.name == name && generic_arguments == other.generic_arguments && singleton == other.singleton
    end
    alias eql? ==

    def hash
      [name, singleton, generic_arguments].hash
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
