require 'pathname'

module Suburb
  module Runtime
    module Discovery
      def find_subu_rbs(file_paths_or_globs)
        Array(file_paths_or_globs)
          .flat_map { find_all_subu_specs(_1) }
          .uniq
      end

      # @param [String] file_path
      # @return [Root|NilClass]
      def find_one_subu_rb(file_path)
        Pathname.new(file_path).ascend do |parent|
          maybe_subu = parent + 'subu.rb'
          return maybe_subu.realpath if maybe_subu.exist?
        end
      end

      def find_all_subu_specs(file_path)
        specs = []
        Pathname.new(file_path).ascend do |parent|
          maybe_subu = parent + 'subu.rb'
          specs << maybe_subu.realpath if maybe_subu.exist?
        end
        specs
      end

      def read_spec(subu_spec_file)
        spec = DSL::Spec.new(subu_spec_file)
        spec.instance_eval(File.read(subu_spec_file))
        spec
      end

      def read_graph(spec)
        raise Runtime::RuntimeError, 'This subu.rb spec does not declare any files.' if spec.files.empty?

        graph = spec.to_dependency_graph
        discover_sub_graphs!(graph, spec, already_visited: [spec.root_path])

        if graph.missing_dependencies.any?
          raise Runtime::RuntimeError, ''"Some targets do not exist, neither as files on disk, nor as outputs in a subu.rb file:

        #{graph.missing_dependencies.map(&:original_path).map(&:to_s).join("\n")}

        "''
        end

        graph
      end

      private

      def discover_sub_graphs!(graph, spec, already_visited: [])
        graph.undeclared_dependencies.each do |dep|
          maybe_subu_rb = find_one_subu_rb(dep.path)
          next unless maybe_subu_rb && !already_visited.include?(maybe_subu_rb.dirname)

          other_spec = DSL::Spec.new(maybe_subu_rb)
          other_spec.instance_eval(File.read(maybe_subu_rb))
          other_graph = other_spec.to_dependency_graph

          discover_sub_graphs!(other_graph, other_spec, already_visited: already_visited + [maybe_subu_rb.dirname])

          graph.merge!(other_graph)
          spec.merge!(other_spec)
        end
      end
    end
  end
end
