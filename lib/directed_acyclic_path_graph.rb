require 'pathname'

class DirectedAcyclicPathGraph
  attr_reader :nodes, :root_path

  def initialize(root_path)
    @root_path = Pathname.new(root_path).realpath
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

    @root_path.ascend do |parent|
      @root_path = parent.realpath if parent == other_graph.root_path
    end
  end

  def all_dependencies_exist?
    @nodes.all? do |_, node|
      node.dependencies.all? do |dep|
        File.exist?(dep.path) || @nodes.any? { |_, other| other != node && other.path == dep.path }
      end
    end
  end

  def add_dependency(from_path, to_path)
    from_node = @nodes[normalize_path(from_path)]
    real_to_path = normalize_path(to_path)
    to_node = @nodes[real_to_path] || Node.new(real_to_path)
    from_node.add_dependency(to_node)
  end

  def normalize_path(path)
    File.expand_path(path, @root_path)
  end
end
