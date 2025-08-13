# frozen_string_literal: true

module Racer
  class RSpecPlugin
    class << self
      attr_accessor :agent_pid

      def configure(config)
        at_exit do
          Racer.flush
        end

        config.before do
          Racer.start(path_regex: %r(\A#{Rails.root.to_s}/(app|lib|test|spec)/), max_generic_depth: 3)
        end

        config.after do
          Racer.stop
        end

        config.after(:suite) do
          Racer.flush
          Racer.stop_agent(Racer::RSpecPlugin.agent_pid)
        end
      end
    end
  end
end
