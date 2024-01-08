require 'pastel'

module Suburb
  module Runtime
    class Lister
      include Discovery

      def initialize(log) = @log = log

      def run(subset)
        pastel = Pastel.new
        sub_specs = Dir.glob('**/subu.rb')
        super_specs = find_all_subu_specs(Dir.pwd)

        specs = (super_specs + sub_specs).map { read_spec(_1) }
        graph = specs.each_with_object(Graph::DependencyGraph.new(Dir.pwd)) do |item, acc|
          acc.merge!(item.to_dependency_graph)
        end

        @log.info 'Files that you can build:'

        if subset
          subset_abs = File.expand_path(subset)
          if glob? subset
            graph.filter_nodes! { File.fnmatch(subset_abs, _1) }
          else
            graph.filter_nodes! { _1.include?(subset_abs) }
          end
        end

        graph.nodes_by_tag.sort.each do |tag, nodes|
          puts pastel.blue.bold(tag) unless tag == ''
          nodes.each do |node|
            print_node node, pastel
          end
        end
      end

      def print_node(node, pastel)
        relative = node.path.relative_path_from(Dir.pwd)
        dir, base = File.split(relative)
        puts "· #{pastel.dark(File.basename($0))} #{pastel.green(dir)}/#{pastel.yellow(base)}"
      end

      def glob?(path)
        path.include?('*')
      end
    end
  end
end
