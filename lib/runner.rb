# frozen_string_literal: true

module Suburb
  class Runner
    require 'pathname'

    class Run
      def rtx(command)
        `rtx exec -- #{command}`
      end
    end

    def run(target_file_path, force)
      subu_rb = find_subu_rb(target_file_path) or
        die("No subu.rb found defining target file '#{target_file_path}' found")
      spec = DSL::Root.new
      spec.instance_eval(File.read(subu_rb))
      dag = spec.to_dag(subu_rb.dirname)

      missing_dependencies = dag.missing_dependecies
      unless missing_dependencies.none?
        raise ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:
        #{missing_dependencies.map(&:original_path)}
        "''
      end

      execute dag, spec, target_file_path, force
    end

    def find_subu_rb(target_file_path)
      Pathname.new(target_file_path).ascend do |parent|
        maybe_subu = parent + 'subu.rb'
        return maybe_subu.realpath if maybe_subu.exist?
      end
    end

    # @param [DirectedAcyclicPathGraph] dag
    # @param [DSL::Root] _subu_spec
    # @param [String] target_file_path
    # @param [Boolean] force
    def execute(dag, subu_spec, target_file_path, force = false)
      target = Pathname.new(target_file_path).expand_path
      raise "No suburb definition for #{target}" unless dag.nodes.include? target.to_s

      root_node = dag.nodes[target.to_s]
      deps = if force
               root_node.all_dependencies.map { lookup(dag, _1) }
             else
               transitive_deps_requiring_build(dag, root_node)
             end

      execute_nodes_in_order(subu_spec, deps + [root_node])
    end

    # @param [DSL::Root] subu_spec
    # @param [Array[Node]] nodes
    def execute_nodes_in_order(subu_spec, nodes)
      bar = TTY::ProgressBar::Multi.new("Building #{nodes.first.path} [:bar]", total: nodes.size)

      nodes_with_bars = nodes.map { [_1, bar.register("#{_1.path.basename} :percent", total: 1)] }

      nodes_with_bars.each do |node, sub_bar|
        builder = subu_spec.builders[node.path.to_s]
        next unless builder

        last_modified = (File.mtime(node.path) if File.exist?(node.path))

        Run.new.instance_exec(node.dependencies.map(&:path), Array(node.path), &builder)

        unless File.exist?(node.path)
          raise ''"Build definition code block failed to create the expected output file:
          #{node.original_path}
          "''
        end

        unless last_modified.nil? || File.mtime(node.path) > last_modified
          raise ''"Build definition code block failed to create the expected output file:
          #{node.original_path}.
          The file is present, but it has not been updated.
          "''
        end

        sub_bar.advance
      end
      bar.finish
    end

    def transitive_deps_requiring_build(dag, root_node)
      modified_since(dag, root_node.path, root_node.dependencies)
    end

    def lookup(dag, dep)
      dag.nodes[dep.path.to_s] || dep
    end

    def modified_since(dag, path, deps)
      actual_deps = deps.map { lookup(dag, _1) }

      grand_children = actual_deps.map do |dep|
        modified_since(dag, dep.path, dep.dependencies)
      end
      children = actual_deps.select do |dep|
        if File.exist?(dep.path) && File.exist?(path)
          File.mtime(dep.path) > File.mtime(path)
        else
          true
        end
      end
      (grand_children + children).flatten
    end

    def die(reason)
      warn reason
      exit 1
    end
  end
end
