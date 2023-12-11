module Suburb
  module Runtime
    class Lister
      include Discovery

      def initialize(log) = @log = log

      def run
        sub_specs = Dir.glob('**/subu.rb')
        super_specs = find_all_subu_specs(Dir.pwd)

        specs = (super_specs + sub_specs).map { read_spec(_1) }
        graph = specs.each_with_object(DependencyGraph.new(Dir.pwd)) do |item, acc|
          acc.merge!(item.to_dependency_graph)
        end

        @log.info 'Available files:'
        graph.nodes.each { |_, node| @log.info node.path.relative_path_from(graph.root_path) }
      end
    end
  end
end
