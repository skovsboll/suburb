# frozen_string_literal: true

require 'pathname'
require_relative './node'

module Suburb
  module Graph
    # DependencyGraph is a directed acyclic graph of normalized file system paths.
    class DependencyGraph
      # @ nodes: Hash[String, Node]
      attr_reader :nodes
      # @ root_path: Pathname
      attr_reader :root_path

      def initialize(root_path)
        raise Suburb::Runtime::RuntimeError, 'A dependency graph must have a root path' unless root_path

        @root_path = Pathname.new(root_path).expand_path

        @nodes = {}
      end

      # @param [String] path
      # @return [Node]
      def add_path(path)
        absolute_path = normalize_path(path)
        explain_outside_root_path!(path, absolute_path, root_path) unless @root_path.child_path?(absolute_path)
        node = Node.new(absolute_path, path, root_path)
        @nodes[absolute_path.to_s] = node
        node
      end

      def add_node(node)
        @nodes[node.path.to_s] = node
        node
      end

      def explain_outside_root_path!(path, absolute_path, root_path)
        raise Suburb::Runtime::RuntimeError, ''"A subu.rb file can not add paths outside root path.
        The root path of the subu.rb is '#{root_path}' You attempted to add a file at
        '#{absolute_path}'. All relative paths in a subu.rb file are considered relative to
        the closest subu.rb file.
        The file you tried to add has the path '#{path}' which, when normalized, is higher in
        the file system than '#{root_path}' (the subu.rb file).
        "''
      end

      # @param [DependencyGraph] other_graph
      def merge!(other_graph)
        @root_path.ascend do |parent|
          @root_path = parent.realpath if parent == other_graph.root_path
        end

        other_graph.nodes.each do |_path, node|
          add_node(node)
        end
        self
      end

      # @return [Array[Node]]
      def missing_dependencies
        @nodes.flat_map do |_, node|
          node.dependencies.select do |dep|
            !::File.exist?(dep.path) && @nodes.none? { |_, other| other != node && other.path == dep.path }
          end
        end
      end

      # @return [Array[Node]]
      def undeclared_dependencies
        @nodes.flat_map do |_, node|
          node.dependencies.select do |dep|
            @nodes.none? { |_, other| other != node && other.path == dep.path }
          end
        end
      end

      # @param [String] from_path
      # @param [String] to_path
      # @return [Node]
      def add_dependency(from_path, to_path)
        from_node = @nodes[normalize_path(from_path).to_s]
        absolute_to_path = normalize_path(to_path).to_s

        # explain_outside_root_path!(to_path, absolute_to_path, root_path) unless @root_path.child_path?(absolute_to_path)

        to_node = @nodes[absolute_to_path] || Node.new(absolute_to_path, to_path, root_path)
        from_node.add_dependency(to_node)

        to_node
      end

      def normalize_path(path)
        Pathname.new(::File.expand_path(path, @root_path))
      end
    end

    # Hierarchy is a mixin for Pathname to determine if a path is a child of another path.
    module Hierarchy
      def child_path?(path)
        path = Pathname.new(path)
        path.ascend do |parent|
          return true if parent == self
        end
        false
      end
    end

    # Pathname is extended with the Hierarchy mixin.
    class ::Pathname
      include Hierarchy
    end
  end
end
