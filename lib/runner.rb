# frozen_string_literal: true

require_relative './err'

module Suburb
  class Runner
    require 'pathname'

    def initialize
      @log = TTY::Logger.new
    end

    class RtxExec
      require 'tty-logger'
      require 'tty-command'

      def initialize
        @cmd = TTY::Command.new
      end

      def rtx(command)
        @cmd.run('rtx', 'x', '--', command) do |_out, err|
          raise Suburb.Err, err if err
        end
      end

      def os
        require 'rbconfig'
        case RbConfig::CONFIG['host_os']
        when /mswin|windows/i
          :windows
        when /linux|unix/i
          :læinux
        when /darwin|mac os/i
          :macos
        else
          :unnkown
        end
      end
    end

    def run(target_file_path, force: false)
      subu_rb = find_subu_rb(target_file_path) or
        die("No subu.rb found defining target file '#{target_file_path}' found")

      run_subu_spec(subu_rb, target_file_path, force:)
    rescue Suburb::Err => e
      @log.error e.message
    end

    def run_subu_spec(subu_rb, target_file_path, force: false)
      spec = DSL::Root.new
      spec.instance_eval(File.read(subu_rb))
      dag = spec.to_dag(subu_rb.dirname)

      dag.undeclared_dependencies.each do |dep|
        maybe_subu_rb = find_subu_rb(dep.path)
        next unless maybe_subu_rb && maybe_subu_rb.dirname != dag.root_path

        other_spec = DSL::Root.new
        other_spec.instance_eval(File.read(maybe_subu_rb))
        other_dag = other_spec.to_dag(maybe_subu_rb.dirname)
        dag.merge!(other_dag)
        spec.merge!(other_spec)
      end

      unless dag.missing_dependencies.none?
        raise Suburb::Err, ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:

        #{dag.missing_dependencies.map(&:original_path).map(&:to_s).join("\n")}

        "''
      end

      execute dag, spec, target_file_path, force:
    end

    # @param [String] file_path
    # @return [Root|NilClass]
    def find_subu_rb(file_path)
      Pathname.new(file_path).ascend do |parent|
        maybe_subu = parent + 'subu.rb'
        return maybe_subu.realpath if maybe_subu.exist?
      end
    end

    # @param [DirectedAcyclicPathGraph] dag
    # @param [DSL::Root] _subu_spec
    # @param [String] target_file_path
    # @param [Boolean] force
    def execute(dag, subu_spec, target_file_path, force: false)
      target = Pathname.new(target_file_path).expand_path
      raise Suburb::Err, "No suburb definition for #{target}" unless dag.nodes.include? target.to_s

      root_node = dag.nodes[target.to_s]
      deps = if force
               root_node.all_dependencies_depthwise.map { lookup(dag, _1) }
             else
               transitive_deps_requiring_build(dag, root_node)
             end

      if deps.any?
        execute_nodes_in_order(subu_spec, deps + [root_node], force:)
      else
        @log.success 'No files require rebuilding.'
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
        RtxExec.new.instance_exec(ins, outs, &builder)
        assert_output_was_built!(node, last_modified)
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

    def transitive_deps_requiring_build(dag, root_node)
      modified_since_depthwise(dag, root_node.path, root_node.dependencies)
    end

    def lookup(dag, dep)
      dag.nodes[dep.path.to_s] || dep
    end

    # @param [DirectedAcyclicPathGraph] dag
    # @param [String] path
    # @param [Array[Node]] deps
    # @return [Array[Node]]
    def modified_since_depthwise(dag, path, deps)
      actual_deps = deps.map { lookup(dag, _1) }
      grand_children = actual_deps.map do |dep|
        modified_since_depthwise(dag, dep.path, dep.dependencies)
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

    def die(reason)
      @log.error reason
      exit 1
    end
  end
end
