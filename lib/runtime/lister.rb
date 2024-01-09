require 'pastel'

module Suburb
  module Runtime
    class Lister
      include Discovery

      def initialize(log) = @log = log

      def run(subsets)
        subsets = Array(subsets).map { ::File.expand_path(_1) }
        pastel = Pastel.new
        sub_specs = Dir.glob('**/subu.rb')
        super_specs = find_all_subu_specs(Dir.pwd)

        specs = (super_specs + sub_specs).map { read_spec(_1) }
        graph = specs.map(&:to_dependency_graph).reduce(&:merge!)

        @log.info 'Files that you can build:'

        if subsets.any?
          graph.filter_nodes! do |node_path, _|
            subsets.any? do |subset|
              if glob? subset
                File.fnmatch(subset, node_path)
              else
                node_path.include?(subset)
              end
            end
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
