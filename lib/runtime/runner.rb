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
        deps_to_build = if force || clean
                          transitive_dependencies(graph, root_node)
                        else
                          transitive_deps_requiring_build(graph, root_node)
                        end

        if deps_to_build.any? || !File.exist?(root_node.path.to_s) || clean || force
          execute_notes_watching_changes(subu_spec, graph, deps_to_build, root_node, clean:, verbose:)
        else
          @log.success 'All files up to date.'
        end
      end

      def execute_notes_watching_changes(subu_spec, graph, deps_to_build, root_node, clean: false, verbose: false)
        watcher = ChangeTracking.new(graph, root_node, deps_to_build)
        execute_nodes_in_order(subu_spec, deps_to_build + [root_node], clean:, verbose:)
        changes = watcher.changes

        @log.warn 'Build predictablity in danger! See suburb.log for details.' if changes.values.flatten.any?

        wan_non_modified_outs(changes) if changes[:non_modified_outs].any?
        warn_non_read_ins(changes) if changes[:non_read_ins].any?
        warn_non_declared_files_read(changes) if changes[:non_declared_files_read].any?
        warn_non_declared_files_modified(changes) if changes[:non_declared_files_modified].any?
        warn_non_created_outs(changes) if changes[:non_created_outs].any?
        warn_non_existing_ins(changes) if changes[:non_existing_ins].any?
      end

      def warn_non_existing_ins(changes)
        @log.warn 'Some files were supposed to be used as dependencies, but do not exist'
        str = changes[:non_existing_ins].map { Pathname.new(_1).relative_path_from(Dir.pwd).to_s }.join("\n")
        @log.debug "\n#{str}"
      end

      def warn_non_created_outs(changes)
        @log.warn 'Some files were supposed to be created, but were not'
        str = changes[:non_created_outs].map do
          Pathname.new(_1).relative_path_from(Dir.pwd).to_s
        end.join("\n")
        @log.debug "\n#{str}"
      end

      def warn_non_declared_files_modified(changes)
        @log.warn 'Some files were modified that are not declared as build targets'
        str = changes[:non_declared_files_modified].map do
          Pathname.new(_1).relative_path_from(Dir.pwd).to_s
        end.join("\n")
        @log.debug "\n#{str}"
      end

      def warn_non_declared_files_read(changes)
        @log.warn 'Some files read that were not declared as dependencies'
        str = changes[:non_declared_files_read].map do
          Pathname.new(_1).relative_path_from(Dir.pwd).to_s
        end.join("\n")
        @log.debug "\n#{str}"
      end

      def warn_non_read_ins(changes)
        @log.warn 'Some files that were supposed to be used as dependencies, were not read'
        str = changes[:non_read_ins].map { Pathname.new(_1).relative_path_from(Dir.pwd).to_s }.join("\n")
        @log.debug "\n#{str}"
      end

      def wan_non_modified_outs(changes)
        @log.warn 'Some files that were supposed to be modified, were not modified'
        str = changes[:non_modified_outs].map do
          Pathname.new(_1).relative_path_from(Dir.pwd).to_s
        end.join("\n")
        @log.debug "\n#{str}"
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
            FileUtils.rm_rf(out_) if File.exist?(out_)
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
