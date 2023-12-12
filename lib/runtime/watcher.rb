require 'filewatcher'

module Suburb
  module Runtime
    class Watcher
      include DependencySorting

      def initialize(graph, node, &block)
        paths_to_watch = transitive_ins(graph, node).map { _1.path.to_s }
        Filewatcher.new(paths_to_watch).watch do |changes|
          block.call(changes)
        end
      end
    end
  end
end
