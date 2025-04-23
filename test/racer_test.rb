# frozen_string_literal: true

require "test_helper"

class TestRacer < Minitest::Test
  write = ARGV.include?("write")

  Dir["test/test_cases/**"].each_with_index do |test_case, index|
    define_method("test_#{test_case}") do
      file = Tempfile.new
      code = <<~RUBY
        require "racer"
        require "tempfile"
        require "#{__dir__}/test_collector"

        out_file = Tempfile.new
        agent_pid = Racer.start_agent(collectors: [TestCollector.new(out: out_file.path)])

        at_exit do
          Racer.flush
          Racer.stop_agent(agent_pid)

          expected = out_file.read
          out_file.close

          unless defined?(DATA)
            if #{write}
              File.write("#{test_case}", "__END__\\n\#{expected}", mode: "a")
            else
              $stderr.puts "Undefined expectation. Please use A=write rake test to generate the expected trace"
            end
            exit
          end

          actual = DATA.read.chomp!

          if actual != expected
            if #{write}
              file = File.open("#{test_case}", "r+")
              file.each do |line|
                if line == "__END__\\n"
                  break
                end
              end

              file.write(expected)
              file.truncate(file.pos)
              file.close
              $stderr.puts("written changes")
            else
              require "difftastic"
              differ =
                ::Difftastic::Differ.new(
                  color: :always,
                  tab_width: 2,
                  syntax_highlight: :off,
                  left_label: "Expected",
                  right_label: "to be equal"
                )

              $stderr.puts differ.diff_objects(actual, expected)
            end
          end
        end

        #{File.read(test_case)}
      RUBY

      file.write(code)
      file.close

      File.write("foo", code)

      _stdout_s, stderr_s, status = Open3.capture3("bundle exec #{Gem.ruby} #{file.path}")

      unless stderr_s.empty?
        assert false, stderr_s
      end

      unless status.success?
        assert false, "Process failed"
      end
    end
  end
end
