# frozen_string_literal: true

require_relative './runtime_error'
require_relative './shell_exec'
require 'tty-logger'
require 'tty-command'
require 'tty-link'
require 'pathname'

module Suburb
  class Runner
    def initialize
      @log_file = TTY::Logger.new do |config|
        config.output = File.open('suburb.log', 'w')
      end
      @terminal_output = TTY::Logger.new
    end

    def run(target_file_path, force: false)
      subu_rb = find_subu_rb(target_file_path) or
        raise Suburb::RuntimeError, "No subu.rb found defining target file '#{target_file_path}' found"

      run_subu_spec(subu_rb, target_file_path, force:)
      TTY::Logger.new.info 'Complete log: cat ./suburb.log'
    end

    def run_subu_spec(subu_rb, target_file_path, force: false)
      spec = DSL::Root.new
      spec.instance_eval(File.read(subu_rb))
      graph = spec.to_dependency_graph(subu_rb.dirname)

      graph.undeclared_dependencies.each do |dep|
        maybe_subu_rb = find_subu_rb(dep.path)
        next unless maybe_subu_rb && maybe_subu_rb.dirname != graph.root_path

        other_spec = DSL::Root.new
        other_spec.instance_eval(File.read(maybe_subu_rb))
        other_graph = other_spec.to_dependency_graph(maybe_subu_rb.dirname)
        graph.merge!(other_graph)
        spec.merge!(other_spec)
      end

      unless graph.missing_dependencies.none?
        raise Suburb::Err, ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:

        #{graph.missing_dependencies.map(&:original_path).map(&:to_s).join("\n")}

        "''
      end

      execute graph, spec, target_file_path, force:
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
        execute_nodes_in_order(subu_spec, deps + [root_node], force:)
      else
        @terminal_output.success 'All files up to date.'
        @log_file.success 'All files up to date.'
      end
    end

    # @param [DSL::Root] subu_spec
    # @param [Array[Node]] nodes
    def execute_nodes_in_order(subu_spec, nodes, force: false)
      with_progress(nodes) do |node|
        builder = subu_spec.builders[node.path.to_s]
        next unless builder

        last_modified = maybe_last_modified(node)
        ins = node.dependencies.map(&:path)
        outs = Array(node.path)
        Dir.chdir(node.root_path) do
          ShellExec.new(@log_file).instance_exec(ins, outs, &builder)
        end
        assert_output_was_built!(node, last_modified)
      rescue ::RuntimeError => e
        raise Suburb::RuntimeError, e
      end
    end

    def maybe_last_modified(node)
      (File.mtime(node.path) if File.exist?(node.path))
    end

    def with_progress(nodes, &block)
      bar = TTY::ProgressBar::Multi.new("Building #{nodes.first.path} [:bar]", total: nodes.size)
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

      raise Suburb::Err, ''"Build definition code block failed to create the expected output file:
          #{node.path}
          "''

      # return if last_modified.nil? || File.mtime(node.path) > last_modified

      # raise ''"Build definition code block failed to create the expected output file:
      #     #{node.path}.
      #     The file is present, but it has not been updated.
      #     "''
    end

    def transitive_deps_requiring_build(graph, root_node)
      modified_since_depthwise(graph, root_node.path, root_node.dependencies)
    end

    def lookup(graph, dep)
      graph.nodes[dep.path.to_s] || dep
    end

    # @param [DependencyGraph] graph
    # @param [String] path
    # @param [Array[Node]] deps
    # @return [Array[Node]]
    def modified_since_depthwise(graph, path, deps)
      actual_deps = deps.map { lookup(graph, _1) }
      grand_children = actual_deps.map do |dep|
        modified_since_depthwise(graph, dep.path, dep.dependencies)
      end
      children = actual_deps.select do |dep|
        file_changed?(path, dep)
      end
      (grand_children + children).flatten
    end

    def file_changed?(path, dep)
      if File.exist?(dep.path) && File.exist?(path)
        File.mtime(dep.path) > File.mtime(path)
      else
        true
      end
    end
  end
end
