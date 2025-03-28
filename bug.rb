TracePoint.new(:call) do |tp|
  binding.irb
end.enable

class A
  def test
  end
end

class B < A
  def test = super
end

B.new.test
