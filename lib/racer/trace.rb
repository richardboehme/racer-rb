class Racer::Trace
  attr_reader :method_owner, :method_name, :return_type, :params

  def initialize(method_owner:, method_name:, return_type:, params:)
    @method_owner = method_owner
    @method_name = method_name
    @return_type = return_type
    @params = params
  end

  class Constant
    attr_reader :name, :type, :path

    TYPES = [
      :module,
      :class
    ].freeze

    def initialize(name:, type:, path:)
      @name = name
      @type = type
      @path = path
    end

    class PathFragment
      attr_reader :name, :type

      def initialize(name:, type:)
        @name = name
        @type = type
      end
    end
  end

  class Param
    attr_reader :name, :class_name, :type

    TYPES = [
      :required,
      :optional,
      :rest,
      :keyword_required,
      :keyword_optional,
      :keyword_rest,
      :block
    ].freeze


    def initialize(name:, class_name:, type:)
      @name = name
      @class_name = class_name
      @type = type
    end

    def ==(other)
      other.name == name && other.class_name == class_name && other.type == type
    end
  end
end
