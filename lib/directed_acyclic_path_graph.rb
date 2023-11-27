require 'pathname'
require_relative 'node'

class DirectedAcyclicPathGraph
  attr_reader :nodes, :root_path

  def initialize(root_path)
    @root_path = Pathname.new(root_path).expand_path
    @nodes = {}
  end

  def add_node(path, &block)
    normalized_path = normalize_path(path)
    raise 'Can not add paths outside root path' unless is_subdir_of?(normalized_path, @root_path)

    node = Node.new(normalized_path, &block)

    @nodes[normalized_path.to_s] = node
  end

  def merge!(other_graph)
    other_graph.nodes.each do |node|
      add_node(node.path)
    end

    @root_path.ascend do |parent|
      @root_path = parent.realpath if parent == other_graph.root_path
    end
  end

  def discover!

    
  end

  def all_dependencies_exist?
    @nodes.all? do |_, node|
      node.dependencies.all? do |dep|
        File.exist?(dep.path) || @nodes.any? { |_, other| other != node && other.path == dep.path }
      end
    end
  end

  def missing_dependecies
    @nodes.flat_map do |_, node|
      node.dependencies.flat_map do |dep|
        File.exist?(dep.path) || @nodes.any? { |_, other| other != node && other.path == dep.path }
      end
    end
  end

  def add_dependency(from_path, to_path)
    from_node = @nodes[normalize_path(from_path).to_s]
    real_to_path = normalize_path(to_path).to_s

    raise 'Can not add paths outside root path' unless is_subdir_of?(real_to_path, @root_path)

    to_node = @nodes[real_to_path] || Node.new(real_to_path)
    from_node.add_dependency(to_node)
  end

  def normalize_path(path)
    Pathname.new(File.expand_path(path, @root_path))
  end

  def is_subdir_of?(path, maybe_root)
    path = Pathname.new(path)
    maybe_root = Pathname.new(maybe_root)
    path.ascend do |parent|
      return true if parent == maybe_root
    end
    false
  end

  def pp
    puts "*** #{@root_path}:"
    @nodes.each { _2.pp(4) }
  end
end
