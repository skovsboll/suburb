# frozen_string_literal: true

require 'tty-logger'
require 'tty-command'
require 'tty-link'
require 'pathname'
require 'uri'
require 'digest/sha1'
require 'base64'
require 'open-uri'

module Suburb
  module Runtime
    class Runner
      include DependencySorting
      include TreeVisualizer
      include Discovery
      include Progress
      include Debug

      def initialize(log)
        @log = log
      end

      def run(targets_paths_or_globs, verbose: false, force: false, watch: false)
        graph = read_graphs(targets_paths_or_globs)
        execute(graph, targets_paths_or_globs, force:, watch:, clean: false, verbose:)
      end

      def clean(targets_paths_or_globs, verbose: false)
        graph = read_graphs(targets_paths_or_globs)
        execute(graph, targets_paths_or_globs, force: false, clean: true, verbose:)
      end

      # @param [DependencyGraph] graph
      # @param [DSL::Root] _subu_spec
      # @param [String] target_file_path
      # @param [Boolean] force
      def execute(graph, targets_paths_or_globs,
                  force: false, watch: false, clean: false, verbose: false)

        target_nodes = Array(targets_paths_or_globs)
                       .map { File.expand_path(_1) }
                       .flat_map do |target_path|
          graph.nodes.filter { |node_path, _| File.fnmatch?(target_path, node_path) }.values
        end.uniq(&:path)

        unless target_nodes.any?
          targets_pp = targets_paths_or_globs.map { Pathname.new(_1).relative_path_from(Dir.pwd) }.join(', ')
          raise Runtime::RuntimeError,
                "No suburb definition for #{targets_pp}"
        end

        target_nodes.each do |node|
          deps = if force || clean
                   transitive_dependencies(graph, node)
                 else
                   transitive_deps_requiring_build(graph, node)
                 end.uniq(&:path)

          if deps.any? || !File.exist?(node.path) || clean || force
            execute_nodes_in_order(graph.spec, deps + [node], clean:, verbose:)
          else
            @log.success 'All files up to date.'
          end
        end
      end

      # @param [DSL::Root] subu_spec
      # @param [Array[Node]] nodes
      def execute_nodes_in_order(subu_spec, nodes, clean: false, verbose: false)
        builders_executed = []

        nodes_with_builder = nodes.select do |node|
          builder = subu_spec.builders[node.path.to_s]
          builder && !builders_executed.include?(builder)
        end.uniq(&:path)

        if verbose
          nodes_with_builder.each do |node|
            builder = subu_spec.builders[node.path.to_s]
            execute_node(node, builder, clean:)
            builders_executed << builder
          end
        else
          with_progress(nodes_with_builder, clean:) do |node|
            builder = subu_spec.builders[node.path.to_s]
            execute_node(node, builder, clean:)
            builders_executed << builder
          end
        end
      end

      def execute_node(node, builder, clean: false)
        ins = node.dependencies.map(&:path)
        outs = Array(node.path)
        if clean
          outs.each do |out_|
            File.delete(out_) if File.exist?(out_)
          end
        else
          Dir.chdir(node.root_path) do
            FileUtils.mkdir_p node.path.dirname
            ShellExec.new(@log).instance_exec(ins, outs, &builder)
          end
        end
        assert_output_was_built!(node) unless clean
      rescue ::RuntimeError => e
        raise Runtime::RuntimeError, e
      rescue Interrupt => _e
        raise Runtime::RuntimeError, 'The build was interrupted.'
      end

      # @param [Node] node
      # @return [Time|NilClass]
      def maybe_last_modified(node)
        (File.mtime(node.path) if File.exist?(node.path))
      end

      def assert_output_was_built!(node)
        return if File.exist?(node.path)

        raise Runtime::RuntimeError, ''"Build definition code block failed to create the expected output file:
          #{node.path}
          "''
      end
    end
  end
end
