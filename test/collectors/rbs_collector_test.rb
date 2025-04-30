# frozen_string_literal: true

require "test_helper"
require "difftastic"

module TestModule; end

class RBSCollectorTest < Minitest::Test
  module A
    class B
      module C
        class D
        end
        module E
        end
      end
    end
  end

  def test_writes_method
    collector = Racer::Collectors::RBSCollector.new

    collector.collect(
      trace(
        name: :foo,
        return_type: String
      )
    )

    assert_rbs(__method__, collector)
  end

  def test_overloads
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, return_type: String),
      trace(name: :foo, return_type: Integer),
      trace(
        name: :foo,
        params: [{ name: :a, klass: Integer, type: :required }],
        return_type: String
      ),
      trace(
        name: :foo,
        params: [{ name: :a, klass: Integer, type: :required }],
        return_type: Integer
      ),
      trace(
        name: :foo,
        params: [{ name: :a, klass: String, type: :required }],
        return_type: String
      ),
      # Ensure that singleton method with same name and type stays separate
      trace(name: :foo, return_type: String, kind: :singleton),
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  def test_singleton_methods
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, kind: :singleton),
      trace(name: :foo, owner: TestModule, kind: :singleton),
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  def test_params
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, params: [
        { name: :a, type: :required },
        { name: :b, type: :optional },
        { name: :args, klass: Array, type: :rest },
        { name: :c, type: :keyword_required },
        { name: :d, type: :keyword_optional },
        { name: :options, klass: Hash, type: :keyword_rest },
        { name: :block, klass: Proc, type: :block },
      ]),
      trace(name: :bar, params: [
        { name: :*, klass: Array, type: :rest },
        { name: :**, klass: Hash, type: :keyword_rest },
        { name: :&, klass: Proc, type: :block }
      ]),
      trace(name: :baz, params: [
        { name: :a, type: :required },
        { name: :args, klass: Array, type: :rest },
        { name: :b, type: :required }
      ]),
      trace(name: :param_without_name, params: [
        { name: nil, type: :required }
      ])
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  def test_generics
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        params: [
          { name: :a, klass: Array, generic_arguments: [[to_constant(String), to_constant(Integer)]], type: :required },
          { name: :b, klass: Hash, generic_arguments: [[to_constant(Symbol), to_constant(String)], [to_constant(Float), to_constant(Regexp)]], type: :required },
          { name: :options, klass: Hash, generic_arguments: [[to_constant(Symbol)], [to_constant(A::B::C::D), to_constant(A::B::C::E)]], type: :keyword_rest }
        ],
        return_type: Hash,
        return_type_generic_arguments: [[to_constant(Symbol), to_constant(A::B)], [to_constant(String)]]
      )
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  def test_namespaces
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        owner: Racer::Agent,
        params: [{ name: :a, klass: A::B::C::D, type: :required }],
        return_type: A::B::C::E,
      ),
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  def test_visibilities
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, visibility: :public),
      trace(name: :bar, visibility: :private),
      trace(name: :baz, visibility: :protected)
    ].each { collector.collect(it) }

    assert_rbs(__method__, collector)
  end

  private

  def write?
    return @write if defined? @write

    @write = ARGV.include?("write")
  end

  def assert_rbs(method_id, collector)
    io = Tempfile.new
    collector.stop(path: io.path)
    io.flush
    actual = io.read

    path = "test/collectors/expected_rbs/#{method_id}.rbs"
    unless File.exist?(path)
      if write?
        File.write(path, actual)
        assert false, "Written file because A=write was set."
      else
        assert false, "Files does not exist. Pass A=write to create the file."
      end
    end

    expected = File.read(path)

    if write? && expected != actual
      File.write(path, actual)
      assert false, "Updated file because A=write was set."
    else
      assert_equal expected, actual, message(nil, "") {
        differ =
          ::Difftastic::Differ.new(
            color: :always,
            tab_width: 2,
            syntax_highlight: :off,
            left_label: "Expected",
            right_label: "to be equal"
          )
        differ.diff_ruby(actual, expected)
      }
    end
  end

  def trace(
    name:,
    return_type: NilClass,
    return_type_generic_arguments: [],
    owner: RBSCollectorTest,
    kind: :instance,
    visibility: :public,
    params: []
  )
    Racer::Trace.new(
      method_owner: to_constant(owner),
      method_name: name,
      method_kind: kind,
      method_visibility: visibility,
      return_type: to_constant(return_type, generic_arguments: return_type_generic_arguments),
      params: params.map { to_param(**it) }
    )
  end

  def to_constant(klass, generic_arguments: [])
    Racer::Trace::Constant.new(
      name: klass.name,
      type: klass.is_a?(Class) ? :class : :module,
      path: klass.name.split("::")[...-1].to_enum.with_object(+"").map do |fragment_name, current_path|
        current_path << "::#{fragment_name}"
        Racer::Trace::Constant::PathFragment.new(
          name: fragment_name.to_sym,
          type: Object.const_get(current_path).is_a?(Class) ? :class : :module
        )
      end,
      generic_arguments:
    )
  end

  def to_param(name:, klass: NilClass, generic_arguments: [], type:)
    Racer::Trace::Param.new(
      name:,
      type_name: to_constant(klass, generic_arguments:),
      type:
    )
  end
end
