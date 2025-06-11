module Racer
  class Railtie < Rails::Railtie
    initializer "racer.extend_active_support_test_case" do
      ActiveSupport.on_load(:active_support_test_case) do
        if defined?(Racer::MinitestPlugin)
          parallelize_teardown do
            Racer.flush
          end

          at_exit do
            Racer.flush
          end

          setup do
            Racer.start(path_regex: %r(\A#{Rails.root.to_s}/(app|lib|test|spec)/), max_generic_depth: 3)
          end

          teardown do
            Racer.stop
          end
        end
      end
    end

    config.before_initialize do
      if defined?(Racer::MinitestPlugin) || defined?(Racer::RSpecPlugin)
        Racer.start(path_regex: %r(\A#{Rails.root.to_s}/(app|lib|test|spec)/), max_generic_depth: 3)
      end
    end

    config.after_initialize do
      if defined?(Racer::MinitestPlugin) || defined?(Racer::RSpecPlugin)
        Racer.stop
        Racer.flush
      end
    end
  end
end
