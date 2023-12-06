# frozen_string_literal: true

require_relative './dependency_graph'
require_relative './dependency_sorting'
require_relative './runtime_error'
require_relative './shell_exec'
require_relative './composite_log'
require 'tty-logger'
require 'tty-command'
require 'tty-link'
require 'pathname'
require 'uri'
require 'digest/sha1'
require 'base64'

module Suburb
  class Runner
    include DependencySorting

    def initialize(log_file, terminal_output)
      @log_file = log_file
      @terminal_output = terminal_output
      @composite_log = CompositeLog.new(@log_file, @terminal_output)
    end

    def run(target_path, force: false)
      run_subu_spec(find_subu_spec!(target_path), target_path, force:, clean: false)
    end

    def clean(target_path)
      run_subu_spec(find_subu_spec!(target_path), target_path, force: false, clean: true)
    end

    def show_tree(target_path)
      subu_rb = find_subu_spec!(target_path)

      spec = DSL::Spec.new
      spec.instance_eval(File.read(subu_rb))
      graph = spec.to_dependency_graph(subu_rb.dirname)
      discover_sub_graphs!(graph, spec, already_visited: [subu_rb.dirname])

      mermaid_source = <<~EOS
        graph TD      
        #{graph.nodes.map { mermaid(_2) }.join("\n") }
      EOS

      encoded_data = Base64.encode64(mermaid_source)
      @terminal_output.info TTY::Link.link_to('View Dependency Tree', "https://mermaid.ink/img/#{encoded_data}")
    end

    def mermaid(node)
      node.dependencies.flat_map { |dep| mermaid(dep) }  +
      node.dependencies.map { |dep| "\t#{Digest::SHA1.hexdigest(node.path.to_s)[0..8]}[#{node.path.basename}]-->#{Digest::SHA1.hexdigest(dep.path.to_s)[0..8]}[#{dep.path.basename}]"}
    end

    def find_subu_spec!(target_path)
      find_subu_rb(target_path) or
        raise Suburb::RuntimeError, "No subu.rb found defining target file '#{target_path}'"
    end

    def run_subu_spec(subu_rb, target_file_path, force: false, clean: false)
      spec = DSL::Spec.new
      spec.instance_eval(File.read(subu_rb))
      graph = spec.to_dependency_graph(subu_rb.dirname)
      discover_sub_graphs!(graph, spec, already_visited: [subu_rb.dirname])

      # pp graph.nodes.map { [_2.path.to_s, _2.dependencies.map(&:path).map(&:to_s)] }.to_h

      unless graph.missing_dependencies.none?
        raise Suburb::RuntimeError, ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:

        #{graph.missing_dependencies.map(&:original_path).map(&:to_s).join("\n")}

        "''
      end

      execute graph, spec, target_file_path, force:, clean:
    end

    def discover_sub_graphs!(graph, spec, already_visited: [])
      graph.undeclared_dependencies.each do |dep|
        maybe_subu_rb = find_subu_rb(dep.path)
        next unless maybe_subu_rb && !already_visited.include?(maybe_subu_rb.dirname)

        other_spec = DSL::Spec.new
        other_spec.instance_eval(File.read(maybe_subu_rb))
        other_graph = other_spec.to_dependency_graph(maybe_subu_rb.dirname)

        discover_sub_graphs!(other_graph, other_spec, already_visited: already_visited + [maybe_subu_rb.dirname])

        graph.merge!(other_graph)
        spec.merge!(other_spec)
      end
    end

    # @param [String] file_path
    # @return [Root|NilClass]
    def find_subu_rb(file_path)
      Pathname.new(file_path).ascend do |parent|
        maybe_subu = parent + 'subu.rb'
        return maybe_subu.realpath if maybe_subu.exist?
      end
    end

    # @param [DependencyGraph] graph
    # @param [DSL::Root] _subu_spec
    # @param [String] target_file_path
    # @param [Boolean] force
    def execute(graph, subu_spec, target_file_path, force: false, clean: false)
      target = Pathname.new(target_file_path).expand_path
      raise Suburb::RuntimeError, "No suburb definition for #{target}" unless graph.nodes.include? target.to_s

      root_node = graph.nodes[target.to_s]
      deps = if force || clean
               transitive_dependencies(graph, root_node)
             else
               transitive_deps_requiring_build(graph, root_node)
             end

      if deps.any?
        execute_nodes_in_order(subu_spec, deps + [root_node], clean:)
      else
        @terminal_output.success 'All files up to date.'
        @log_file.success 'All files up to date.'
      end
    end

    # @param [DSL::Root] subu_spec
    # @param [Array[Node]] nodes
    def execute_nodes_in_order(subu_spec, nodes, clean: false)
      builders_executed = []

      nodes_with_builder = nodes.select { |node|
        builder = subu_spec.builders[node.path.to_s]
        builder && !builders_executed.include?(builder)
      }

      with_progress(nodes_with_builder, clean:) do |node|
        last_modified = maybe_last_modified(node)
        ins = node.dependencies.map(&:path)
        outs = Array(node.path)
        log = node.stdout ? @composite_log : @log_file
        if clean
          outs.each do |out_|
            File.delete(out_) if File.exist?(out_)
          end
        else
        Dir.chdir(node.root_path) do
          builder = subu_spec.builders[node.path.to_s]
          ShellExec.new(log).instance_exec(ins, outs, &builder)
          builders_executed << builder
        end
      end
        assert_output_was_built!(node, last_modified) unless clean
      rescue ::RuntimeError => e
        raise Suburb::RuntimeError, e
      end
    end

    # @param [Node] node
    # @return [Time|NilClass]
    def maybe_last_modified(node)
      (File.mtime(node.path) if File.exist?(node.path))
    end

    def with_progress(nodes, clean: false, &block)
      bar = TTY::ProgressBar::Multi.new("#{clean ? 'Cleaning' : 'Building'} #{nodes.last.original_path} [:bar]", total: nodes.size)
      nodes_with_bars = nodes.map { [_1, bar.register("#{_1.original_path}", total: 1)] }
      nodes_with_bars.each do |node, sub_bar|
        block[node]
        sub_bar.advance
      end
    ensure
      bar.finish
    end

    def assert_output_was_built!(node, _last_modified)
      return if File.exist?(node.path)

      raise Suburb::RuntimeError, ''"Build definition code block failed to create the expected output file:
          #{node.path}
          "''
    end
  end
end
