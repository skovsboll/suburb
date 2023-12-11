# frozen_string_literal: true

module Suburb
  module Runtime
    module DependencySorting
      # @param [DependencyGraph] graph
      # @param [Node] node
      # @return [Array[Node]] a flat list of nodes to build, in order
      def transitive_deps_requiring_build(graph, node)
        modified_since_depthwise(graph, node)
      end

      # @param [DependencyGraph] graph
      # @param [Node] node
      # @return [Array[Node]] all dependencies of the node, including transitive dependencies
      def transitive_dependencies(graph, node, already_visited: [])
        if already_visited.include?(node.path.to_s)
          raise Suburb::CyclicDependencyError.new("Cyclic dependency detected: #{node.original_path}", graph, node)
        end

        deps = node
               .dependencies
               .map { lookup(graph, _1) }

        deps
          .flat_map { transitive_dependencies(graph, _1, already_visited: already_visited + [node.path.to_s]) } + deps
      end

      # @param [DependencyGraph] graph
      # @param [Node] node
      # @return [Node] The node that has a build definition, if it is registered
      def lookup(graph, node)
        graph.nodes[node.path.to_s] || node
      end

      # @param [DependencyGraph] graph
      # @param [Node] node
      # @return [Array[Node]]
      def modified_since_depthwise(graph, node)
        transitive_dependencies(graph, node)
          .select do |dep_node|
            output_file_needs_building?(node.path.to_s, dep_node.path.to_s)
          end
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
  end
end
