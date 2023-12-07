require 'pathname'
require_relative 'dsl/spec'

module Suburb
  module Discovery
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
  end
end
