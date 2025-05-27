require "racer/racer"
require "racer/trace"
require "racer/collectors/rbs_collector"
require "racer/agent"

require "racer/rails/railtie" if defined?(Rails::Railtie)

require "socket"

module Racer
  SERVER_PATH = "/tmp/racer.sock"

  def self.start_agent(collectors: [Racer::Collectors::RBSCollector.new], stop_at_exit: true)
    pid = fork(&Racer::Agent.new(SERVER_PATH, collectors).method(:start))

    until File.exist?(SERVER_PATH)
      sleep 0.1
    end

    at_exit do
      flush
      if stop_at_exit
        stop_agent(pid)
      end
    end

    pid
  end

  def self.stop_agent(pid)
    Process.kill("HUP", pid)
    Process.wait(pid)
  rescue Errno::ESRCH
    # Agent already stopped
  end

  def self.start(path_regex: nil, max_generic_depth: 2)
    __c_start(path_regex, max_generic_depth)
  end
end
