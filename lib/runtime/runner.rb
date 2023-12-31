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

      def run(target_path, verbose: false, force: false, watch: false)
        run_subu_spec(find_subu_spec!(target_path), target_path, force:, watch:, clean: false, verbose:)
      end

      def clean(target_path, verbose: false)
        run_subu_spec(find_subu_spec!(target_path), target_path, force: false, clean: true, verbose:)
      end

      def find_subu_spec!(target_path)
        find_subu_rb(target_path) or
          raise Runtime::RuntimeError, "No subu.rb found defining target file '#{target_path}'"
      end

      def run_subu_spec(subu_rb, target_file_path, force: false, watch: false, clean: false, verbose: false)
        spec = read_spec(subu_rb)
        graph = read_graph(spec)
        execute graph, spec, target_file_path, force:, watch:, clean:, verbose:
      end

      # @param [DependencyGraph] graph
      # @param [DSL::Root] _subu_spec
      # @param [String] target_file_path
      # @param [Boolean] force
      def execute(graph, subu_spec, target_file_path, force: false, watch: false, clean: false, verbose: false)
        target = Pathname.new(target_file_path).expand_path
        raise Runtime::RuntimeError, "No suburb definition for #{target}" unless graph.nodes.include? target.to_s

        root_node = graph.nodes[target.to_s]
        deps = if force || clean
                 transitive_dependencies(graph, root_node)
               else
                 transitive_deps_requiring_build(graph, root_node)
               end

        if deps.any? || !File.exist?(root_node.path.to_s) || clean || force
          execute_nodes_in_order(subu_spec, deps + [root_node], clean:, verbose:)
        else
          @log.success 'All files up to date.'
        end
      end

      # @param [DSL::Root] subu_spec
      # @param [Array[Node]] nodes
      def execute_nodes_in_order(subu_spec, nodes, clean: false, verbose: false)
        builders_executed = []

        nodes_with_builder = nodes.select do |node|
          builder = subu_spec.builders[node.path.to_s]
          builder && !builders_executed.include?(builder)
        end

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
