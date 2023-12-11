class Suburb::Runtime::RuntimeError < RuntimeError
end

class Suburb::Runtime::CyclicDependencyError < RuntimeError
  attr_reader :graph, :node

  def initialize(message, graph, node)
    super(message)
    @graph = graph
    @node = node
  end
end
