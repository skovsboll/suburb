require 'tty-link'

module Suburb
  module TreeVisualizer
    def iterm2?
      TTY::Link.support_link?
    end

    def show_tree_and_link(target_path)
      subu_rb = find_subu_spec!(target_path)

      spec = DSL::Spec.new
      spec.instance_eval(File.read(subu_rb))
      graph = spec.to_dependency_graph(subu_rb.dirname)
      discover_sub_graphs!(graph, spec, already_visited: [subu_rb.dirname])

      show_graph_tree(graph)
    end

    def show_graph_tree(graph)
      graph_nodes = graph.nodes.map { mermaid(_2) }.flatten.uniq
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
