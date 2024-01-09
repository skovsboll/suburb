require 'filewatcher'
require_relative './dependency_sorting'

module Suburb
  module Runtime
    class Watcher
      include Runtime::DependencySorting

      attr_reader :ins_to_watch,
                  :outs_to_watch,
                  :files_to_watch

      def initialize(graph, node)
        @ins_to_watch = transitive_ins(graph, node).map { _1.path.to_s }.uniq
        @outs_to_watch = transitive_outs(graph, node).map { _1.path.to_s }.uniq
        @files_to_watch = (@ins_to_watch + @outs_to_watch).uniq
      end

      def watching(&block)
        files_per_event = {}
        watcher = Filewatcher.new(@files_to_watch).watch do |changes|
          changes.each do |filename, event|
            path = File.expand_path(filename)
            files_per_event[event] ||= []
            files_per_event[event] << path
          end
        end
        block.call
        files_per_event
      end
    end
  end
end
