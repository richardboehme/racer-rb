require "racer/racer"
require "racer/trace"
require "racer/collectors/rbs_collector"
require "racer/agent"

require "drb"
require "drb/unix" unless Gem.win_platform?

module Racer
  SERVER_PATH = "/tmp/racer.sock"

  def self.start_agent
    fork(&Racer::Agent.new(SERVER_PATH).method(:start))

    at_exit do
      flush
    end
  end
end
