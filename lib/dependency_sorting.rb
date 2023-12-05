# frozen_string_literal: true

require_relative './dependency_graph'

module DependencySorting
  # @param [DependencyGraph] graph
  # @param [Node] node
  # @return [Array[Node]] a flat list of nodes to build, in order
  def transitive_deps_requiring_build(graph, node)
    modified_since_depthwise(graph, node.path, node.dependencies)
  end

  # @param [DependencyGraph] graph
  # @param [Node] node
  # @return [Node] The node that has a build definition, if it is registered
  def lookup(graph, node)
    graph.nodes[node.path.to_s] || node
  end

  # @param [DependencyGraph] graph
  # @param [String] path
  # @param [Array[Node]] deps
  # @return [Array[Node]]
  def modified_since_depthwise(graph, path, deps)
    actual_deps = deps.map { lookup(graph, _1) }
    grand_children = actual_deps.map do |dep|
      modified_since_depthwise(graph, dep.path, dep.dependencies)
    end
    children = actual_deps.select do |dep|
      output_file_needs_building?(path, dep.path)
    end
    (grand_children + children).flatten
  end

  # @param [String] path
  # @param [Node] dep
  # @return [Boolean] true if the file needs to be built or re-built
  def output_file_needs_building?(out_path, dependency_path)
    if File.exist?(dependency_path) && File.exist?(out_path)
      File.mtime(dependency_path) > File.mtime(out_path)
    else
      true
    end
  end
end
