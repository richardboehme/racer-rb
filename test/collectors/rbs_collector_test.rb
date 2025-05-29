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
        class F
        end
      end
    end
  end

  def test_writes_method
    collector = Racer::Collectors::RBSCollector.new

    collector.collect(
      trace(
        name: :foo,
        return_type: String,
        constant_updates: [String]
      )
    )

    assert_rbs(__method__, collector)
  end

  def test_overloads
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, return_type: String, constant_updates: [String]),
      trace(name: :foo, return_type: Integer, constant_updates: [Integer]),
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
      trace(
        name: :bar,
        params: [{ name: :a, klass: Array, generic_arguments: [[Integer]], type: :required }],
        return_type: Integer,
        constant_updates: [Array]
      ),
      trace(
        name: :bar,
        params: [{ name: :a, klass: Array, generic_arguments: [[String]], type: :required }],
        return_type: String
      )
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_singleton_methods
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, kind: :singleton),
      trace(name: :foo, owner: TestModule, kind: :singleton, constant_updates: [TestModule]),
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_params
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        params: [
          { name: :a, type: :required },
          { name: :b, type: :optional },
          { name: :args, klass: Array, type: :rest },
          { name: :c, type: :keyword_required },
          { name: :d, type: :keyword_optional },
          { name: :options, klass: Hash, type: :keyword_rest }
        ],
        block_param: to_block_param(traces: []),
        constant_updates: [Array, Hash]
      ),
      trace(name: :bar, params: [
        { name: :*, klass: Array, type: :rest },
        { name: :**, klass: Hash, type: :keyword_rest }
      ]),
      trace(name: :baz, params: [
        { name: :a, type: :required },
        { name: :args, klass: Array, type: :rest },
        { name: :b, type: :required }
      ]),
      trace(name: :param_without_name, params: [
        { name: nil, type: :required }
      ])
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_generics
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        params: [
          {
            name: :a,
            klass: Array,
            generic_arguments: [
              [String, to_constant_instance(Array, generic_arguments: [[Integer, String]])]
            ],
            type: :required
          },
          { name: :args, klass: Array, generic_arguments: [[A::B::C::D, A::B::C::E]], type: :rest },
          { name: :b, klass: Hash, generic_arguments: [[Symbol, String], [Float, Regexp]], type: :required },
          { name: :options, klass: Hash, generic_arguments: [[Symbol], [A::B::C::D, A::B::C::E]], type: :keyword_rest }
        ],
        return_type:
          to_constant_instance(
            Hash,
            generic_arguments: [
              [
                Symbol,
                A::B,
                to_constant_instance(Hash, generic_arguments: [[to_constant_instance(Array, generic_arguments: [[Integer]])], [Integer, Symbol]])
              ],
              [String]
            ]
          ),
        constant_updates: [Array, Hash, Symbol, Integer, String, A, A::B, A::B::C, A::B::C::D, A::B::C::E]
      )
    ].each { collector.collect(_1) }

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
        constant_updates: [Racer, Racer::Agent, RBSCollectorTest, A, A::B, A::B::C, A::B::C::D, A::B::C::E]
      ),
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_visibilities
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, visibility: :public),
      trace(name: :bar, visibility: :private),
      trace(name: :baz, visibility: :protected)
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_extend_existing_classes
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :prime?, owner: Integer, constant_updates: [Integer]),
      trace(name: :+, owner: Integer),
      trace(name: :bar, owner: Integer, kind: :singleton),
      trace(name: :sqrt, owner: Integer, kind: :singleton),
      trace(name: :foo, owner: Hash, constant_updates: [Hash]),
      trace(name: :initialize, owner: Hash, visibility: :private),
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_literals
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        params: [
          { name: :a, klass: FalseClass, type: :required },
          { name: :b, klass: TrueClass, type: :required },
          { name: :c, klass: NilClass, type: :required }
        ],
        return_type: TrueClass,
        constant_updates: [FalseClass, TrueClass, NilClass]
      ),
      trace(name: :bar, return_type: FalseClass),
      trace(name: :baz, return_type: NilClass),
      trace(name: :union, return_type: TrueClass),
      trace(name: :union, return_type: FalseClass),
      trace(name: :union, return_type: NilClass)
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_blocks
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        block_param: to_block_param(
          traces: [
            {
              params: [
                { name: :a, klass: String, type: :required },
                { name: :b, klass: Integer, type: :optional }
              ],
              return_type: A::B::C::D,
              self_type: String
            },
            {
              params: [
                { name: :a, klass: A::B::C::E, type: :required },
                { name: :b, klass: Integer, type: :optional }
              ],
              return_type: String,
              self_type: Integer
            },
          ]
        ),
        constant_updates: [String, Integer, A, A::B, A::B::C, A::B::C::D, A::B::C::E]
      ),
      trace(
        name: :foo,
        block_param: to_block_param(traces: [])
      ),
      trace(
        name: :foo,
        block_param: to_block_param(traces: [{ params: [], return_type: String }])
      ),
      trace(
        name: :foo,
        block_param: to_block_param(traces: [{ params: [], return_type: Integer }])
      ),
      trace(
        name: :foo,
        block_param: to_block_param(traces: [{ params: [{ name: :a, klass: String, type: :required }], return_type: Integer }])
      ),
      trace(
        name: :bar,
        block_param: to_block_param(traces: [{ self_type: to_constant_instance(A::B::C::F, singleton: true) }]),
        constant_updates: [A::B::C::F]
      )
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_inheritance_chain
    collector = Racer::Collectors::RBSCollector.new(libraries: ["tempfile"])

    [
      trace(name: :foo, constant_updates: [
        RBSCollectorTest,
        A,
        A::B,
        A::B::C,
        to_constant(A::B::C::D, superclass: A::B, included_modules: [A, A::B::C], prepended_modules: [A::B::C::E], extended_modules: [A]),
        to_constant(A::B::C::E, included_modules: [A], prepended_modules: [A::B::C], extended_modules: [A::B::C]),
        A::B::C::F,
        Enumerable,
        Array,
        Racer,
        to_constant(Racer::Agent, superclass: Array),
        to_constant(Object, included_modules: [A, Enumerable]),
        "Delegator1234",
        # Should use existing superclass if present (in this case File)
        to_constant(Tempfile, superclass: "Delegator1234"),
      ])
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_invalid_constant_names
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :foo,
        constant_updates: [
          # Those classes actually exist and cause syntax errors in RBS
          to_constant("IO::generic_readable"),
          to_constant(IO, included_modules: ["IO::generic_readable"]),
          to_constant("IO::generic_writable"),
          to_constant("IO::Bar"),
          to_constant("IO::Bar::invalid"),
          to_constant("IO::Foo"),
          to_constant("IO::Foo::invalid_constant"),
          to_constant(Array)
        ],
        params: [{ name: :a, klass: "IO::generic_writable", type: :required }],
        return_type: to_constant_instance("Array", generic_arguments: [["IO::Foo::invalid_constant"]])
      ),
      trace(name: :foo, return_type: to_constant_instance("IO::Bar::invalid"))
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_drop_invalid_method_names
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(
        name: :"` test: foo bar`",
      )
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_interface_methods
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, constant_updates: [
        Enumerable,
        Comparable,
        to_constant(A::B, included_modules: [Enumerable]),
        to_constant(A::B::C::F, prepended_modules: [Enumerable]),
        to_constant(A::B::C::D, extended_modules: [Enumerable]),
        to_constant(String, included_modules: [Comparable])
      ])
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_unnamed_rbs_classes
    collector = Racer::Collectors::RBSCollector.new

    [
      trace(name: :foo, constant_updates: [
        Random::Base,
        to_constant(Random, superclass: Random::Base)
      ])
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  def test_different_callee
    collector = Racer::Collectors::RBSCollector.new(libraries: ["json"])

    [
      trace(
        name: :foo,
        constant_updates: [
          A::B
        ],
        params: [{ name: :a, klass: String, type: :required }],
        return_type: Integer,
        callee: A::B
      ),
      trace(
        name: :to_json,
        constant_updates: [
          A,
          to_constant(Array, included_modules: [A])
        ],
        owner: A,
        callee: Array
      )
    ].each { collector.collect(_1) }

    assert_rbs(__method__, collector)
  end

  private

  def write?
    return @write if defined? @write

    @write = ARGV.include?("write")
  end

  def assert_rbs(method_id, collector)
    Dir.mktmpdir do |directory|
      collector.stop(path: directory)

      expected_path = "test/collectors/expected_rbs/#{method_id}"
      expected_files = Dir["#{expected_path}/**.rbs"]

      if expected_files.empty?
        if write?
          FileUtils.mv(directory, expected_path)
          # At the end of the block Dir.mktmpdir tries to remove the directory so it needs to be present
          FileUtils.mkdir(directory)
          assert false, "Written file because A=write was set."
        else
          assert false, "Files do not exist. Pass A=write to create the file."
        end
      end

      expected_files.each do |file_path|
        expected = File.read(file_path)
        actual_path = File.join(directory, File.basename(file_path))
        actual =
          if File.exist?(actual_path)
            File.read(actual_path)
          end

        if write? && expected != actual
          if actual
            File.write(file_path, actual)
          else
            File.delete(file_path)
          end

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
    end
  end

  def trace(
    name:,
    return_type: NilClass,
    owner: RBSCollectorTest,
    callee: nil,
    kind: :instance,
    visibility: :public,
    params: [],
    block_param: nil,
    constant_updates: []
  )
    if owner == RBSCollectorTest
      constant_updates << RBSCollectorTest
    end

    Racer::Trace.new(
      method_owner: to_constant_instance(owner),
      method_callee: callee && to_constant_instance(callee),
      method_name: name.to_s,
      method_kind: kind,
      method_visibility: visibility,
      return_type: to_constant_instance(return_type),
      params: params.map { to_param(**_1) },
      block_param:,
      constant_updates: constant_updates.map { to_constant(_1) }
    )
  end

  def to_constant(klass, anonymous: false, superclass: nil, included_modules: [], prepended_modules: [], extended_modules: [])
    return klass if klass.is_a?(Racer::Trace::Constant)

    Racer::Trace::Constant.new(
      name: klass.to_s,
      anonymous:,
      type: klass.is_a?(Class) ? :class : :module,
      superclass: superclass && superclass.to_s,
      included_modules: included_modules.map(&:to_s),
      prepended_modules: prepended_modules.map(&:to_s),
      extended_modules: extended_modules.map(&:to_s)
    )
  end

  def to_param(name:, klass: NilClass, generic_arguments: [], type:)
    Racer::Trace::Param.new(
      name:,
      type_name: to_constant_instance(klass, generic_arguments:),
      type:
    )
  end

  def to_block_param(traces:, name: :block)
    Racer::Trace::BlockParam.new(
      name:,
      traces: traces.map { to_block_trace(**_1) }
    )
  end

  def to_block_trace(params: [], self_type: nil, return_type: NilClass, block_param: nil)
    Racer::Trace::BlockTrace.new(
      self_type: self_type && to_constant_instance(self_type),
      params: params.map { to_param(**_1) },
      return_type: to_constant_instance(return_type),
      block_param:
    )
  end

  def to_constant_instance(name, singleton: false, generic_arguments: [])
    return name if name.is_a?(Racer::Trace::ConstantInstance)

    Racer::Trace::ConstantInstance.new(
      name: name.to_s,
      singleton:,
      generic_arguments: generic_arguments.map { |union| union.map { to_constant_instance(_1) } }
    )
  end
end
