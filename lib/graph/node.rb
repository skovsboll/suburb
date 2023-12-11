# frozen_string_literal: true

module Suburb
  module Graph
    # A tree like structure.
    # A node represents an absolute, normalized path in a file system and its dependent nodes.
    # Does not allow cyclic dependecies.
    class Node
      attr_accessor :path, :dependencies, :original_path, :root_path, :stdout

      def initialize(path, original_path, root_path, stdout: false)
        @path = Pathname.new(path)
        raise 'A node must be constructed with a absolute path' unless @path.absolute?

        @original_path = original_path

        raise 'A node must know its root path' unless root_path

        @root_path = root_path
        @dependencies = []
        @stdout = stdout
      end

      def add_dependency(node)
        raise 'Can not add depenency to one self' if node.path == path

        if @dependencies.include?(node) || circular_dependency?(node)
          raise 'Circular dependency or duplicate node detected'
        end

        @dependencies << node
      end

      def circular_dependency?(node)
        node.dependencies.include?(self) || node.dependencies.any? { |dep| circular_dependency?(dep) }
      end

      def all_dependencies_depthwise
        @dependencies.flat_map(&:all_dependencies_depthwise) + @dependencies
      end
    end
  end
end