# frozen_string_literal: true

module Racer
  class MinitestPlugin
    class << self
      attr_accessor :agent_pid
    end

    def self.minitest_plugin_init(options)
      Minitest.reporter << reporter(**options)
    end

    def self.reporter(**options)
      Reporter.new(pid: agent_pid, **options)
    end

    # Do not subclass Minitest::AbstractReporter to be compatible with minitest-reporters
    # (they expect an #io= method)
    class Reporter < Minitest::Reporter
      def initialize(pid:, **)
        @pid = pid
        super()
      end

      def report
        Racer.flush
        Racer.stop_agent(@pid)
      end

      # Compatibility with minitest-reporters gem
      def before_test(*); end
      def after_test(*); end
    end
  end
end
