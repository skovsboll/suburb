require 'tty-link'
require_relative './discovery'

module Suburb
  module Runtime
    module TreeVisualizer
      include DependencySorting
      include Discovery

      def iterm2?
        TTY::Link.support_link?
      end

      def show_tree_and_link(targets_paths_or_globs)
        graph = read_graphs(targets_paths_or_globs)

        target_nodes = Array(targets_paths_or_globs)
                       .map { File.expand_path(_1) }
                       .flat_map do |target_path|
          graph.nodes.filter { |node_path, _| File.fnmatch?(target_path, node_path) }.values
        end.uniq(&:path)

        all_deps = target_nodes.flat_map { transitive_dependencies(graph, _1) }.uniq(&:path)

        show_graph_tree(target_nodes + all_deps)
      end

      def show_graph_tree(nodes)
        graph_nodes = nodes.map { mermaid(_1) }.flatten.uniq
        mermaid_source = <<~EOS
          graph LR; #{graph_nodes.join(';')}
        EOS

        encoded_data = Base64.strict_encode64(mermaid_source)
        image_url = "https://mermaid.ink/img/#{encoded_data}?bgColor=585"
        uri = URI.parse(image_url.strip)
        image_binary = uri.read
        encoded_image = Base64.strict_encode64(image_binary)

        # Print img to iterm2
        puts "\x1B]1337;File=inline=1;width=100:#{encoded_image}\x07"

        TTY::Link.link_to('View Dependency Tree in browser', image_url)
      end

      private

      def mermaid(node)
        node.dependencies.flat_map { |dep| mermaid(dep) } +
          node.dependencies.map do |dep|
            "#{Digest::SHA1.hexdigest(node.path.to_s)[0..8]}[#{node.path.relative_path_from(Dir.pwd)}]-->#{Digest::SHA1.hexdigest(dep.path.to_s)[0..8]}[#{dep.path.relative_path_from(Dir.pwd)}]"
          end
      end
    end
  end
end
