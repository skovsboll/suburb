class Suburb::RuntimeError < RuntimeError
end

class Suburb::CyclicDependencyError < RuntimeError
  attr_reader :graph, :node

  def initialize(message, graph, node)
    super(message)
    @graph = graph
    @node = node
  end
end
