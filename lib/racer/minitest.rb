# This ensures that racer can inject it's railtie even if rails was not fully required yet
#
# This happens if running a test with a path argument because the test:prepare task is not being executed and rails did not fully initialize
# when requiring racer/minitest.
#
# If no path argument was passed the rails:prepare rake task is being executed. In this case racer is being required during the rails boot process
# and installs the railtie accordingly.
require "rails" if defined?(Rails)

require "racer"
require_relative "minitest_plugin"

pid = Racer.start_agent(stop_at_exit: false)
puts "Agent started with pid #{pid}"
Racer::MinitestPlugin.agent_pid = pid

Minitest.register_plugin Racer::MinitestPlugin
