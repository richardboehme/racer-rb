class TestCollector
  attr_reader :traces

  def initialize(out:)
    @traces = []
    @out = out
  end

  def collect(trace)
    @traces << trace
  end

  def stop
    puts "Writing #{@traces.to_yaml} to #{@out}"
    File.write(@out, @traces.to_yaml)
  end
end
