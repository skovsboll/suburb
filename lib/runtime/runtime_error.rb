module Suburb
  module Runtime
    class RuntimeError < RuntimeError
    end

    class CyclicDependencyError < RuntimeError
      attr_reader :graph, :node

      def initialize(message, graph, node)
        super(message)
        @graph = graph
        @node = node
      end
    end
  end
end
