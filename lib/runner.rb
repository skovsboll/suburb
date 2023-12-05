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

module Suburb
  class Runner
    include DependencySorting

    def initialize(log_file, terminal_output)
      @log_file = log_file
      @terminal_output = terminal_output
      @composite_log = CompositeLog.new(@log_file, @terminal_output)
    end

    def run(target_file_path, force: false)
      subu_rb = find_subu_rb(target_file_path) or
        raise Suburb::RuntimeError, "No subu.rb found defining target file '#{target_file_path}' found"

      run_subu_spec(subu_rb, target_file_path, force:)
      TTY::Logger.new.info 'Complete log: cat ./suburb.log'
    end

    def run_subu_spec(subu_rb, target_file_path, force: false)
      spec = DSL::Spec.new
      spec.instance_eval(File.read(subu_rb))
      graph = spec.to_dependency_graph(subu_rb.dirname)

      discover_sub_graphs!(graph, spec)

      unless graph.missing_dependencies.none?
        raise Suburb::RuntimeError, ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:

        #{graph.missing_dependencies.map(&:original_path).map(&:to_s).join("\n")}

        "''
      end

      execute graph, spec, target_file_path, force:
    end

    def discover_sub_graphs!(graph, spec)
      graph.undeclared_dependencies.each do |dep|
        maybe_subu_rb = find_subu_rb(dep.path)
        next unless maybe_subu_rb && maybe_subu_rb.dirname != graph.root_path

        other_spec = DSL::Spec.new
        other_spec.instance_eval(File.read(maybe_subu_rb))
        other_graph = other_spec.to_dependency_graph(maybe_subu_rb.dirname)
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
    def execute(graph, subu_spec, target_file_path, force: false)
      target = Pathname.new(target_file_path).expand_path
      raise Suburb::RuntimeError, "No suburb definition for #{target}" unless graph.nodes.include? target.to_s

      root_node = graph.nodes[target.to_s]
      deps = if force
               root_node.all_dependencies_depthwise.map { lookup(graph, _1) }
             else
               transitive_deps_requiring_build(graph, root_node)
             end

      if deps.any?
        execute_nodes_in_order(subu_spec, deps + [root_node])
      else
        @terminal_output.success 'All files up to date.'
        @log_file.success 'All files up to date.'
      end
    end

    # @param [DSL::Root] subu_spec
    # @param [Array[Node]] nodes
    def execute_nodes_in_order(subu_spec, nodes)
      builders_executed = []
      with_progress(nodes) do |node|
        builder = subu_spec.builders[node.path.to_s]
        next unless builder || builders_executed.include?(builder)

        last_modified = maybe_last_modified(node)
        ins = node.dependencies.map(&:path)
        outs = Array(node.path)
        log = node.stdout ? @composite_log : @log_file
        Dir.chdir(node.root_path) do
          ShellExec.new(log).instance_exec(ins, outs, &builder)
        end
        builders_executed << builder
        assert_output_was_built!(node, last_modified)
      rescue ::RuntimeError => e
        raise Suburb::RuntimeError, e
      end
    end

    # @param [Node] node
    # @return [Time|NilClass]
    def maybe_last_modified(node)
      (File.mtime(node.path) if File.exist?(node.path))
    end

    def with_progress(nodes, &block)
      bar = TTY::ProgressBar::Multi.new("Building #{nodes.last.path} [:bar]", total: nodes.size)
      nodes_with_bars = nodes.map { [_1, bar.register("#{_1.path.basename} :percent", total: 1)] }
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
