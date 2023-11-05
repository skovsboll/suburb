class DirectedAcyclicPathGraph
  attr_reader :nodes

  def initialize(root_path)
    @root_path = File.expand_path(without_lakefile(root_path))
    @nodes = {}
  end

  def add_node(path)
    normalized_path = normalize_path(path)
    node = Node.new(normalized_path)
    @nodes[normalized_path] = node
  end

  def merge!(other_graph)
    other_graph.nodes.each do |node|
      add_node(node.path)
    end
  end

  def add_dependency(from_path, to_path)
    from_node = @nodes[normalize_path(from_path)]
    to_node = @nodes[normalize_path(to_path)]
    from_node.add_dependency(to_node)
  end

  def normalize_path(path)
    File.expand_path(path, @root_path)
  end

  def without_lakefile(path)
    if File.basename(path) == 'Lakefile'
      File.dirname(path)
    else
      path
    end
  end
end
