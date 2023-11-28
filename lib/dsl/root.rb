# frozen_string_literal: true

require_relative './file'

module Suburb
  module DSL
    class Root
      def files
        @files ||= []
      end

      def builders
        @builders ||= {}
      end

      def file(outs, ins: [], &block)
        files << DSL::File.new(outs, ins, &block)
      end

      def to_dag(root_path)
        dag = DirectedAcyclicPathGraph.new(root_path)
        files.each do |f|
          f.outs.each do |out|
            add_out(dag, out, f.ins, &f.builder)
          end
        end
        dag
      end

      def merge!(other_spec)
        @files += other_spec.files
        @builders.merge!(other_spec.builders)
      end

      def add_out(dag, out, ins, &builder)
        case out
        in Proc => proc
          ins
            .map { ::File.expand_path(_1, dag.root_path) }
            .map { proc.call(Pathname.new(_1)) }
            .each do |out_|
              dag.add_node(out_)
              builders[out_] = builder
              ins.each do |in_|
                add_in(dag, in_, out_)
              end
            end
        in String => out_
          node = dag.add_node(out_)
          builders[node.path.to_s] = builder
          ins.each do |in_|
            add_in(dag, in_, out_)
          end
        end
      end

      def add_in(dag, in_, out)
        path = ::File.expand_path(in_, dag.root_path)

        if is_glob(path)
          Dir.glob(path) do |expanded|
            fn = Pathname.new(expanded).basename
            dag.add_dependency(out, expanded) if fn != 'subu.rb'
          end
        else
          dag.add_dependency(out, path)
        end
      end

      def is_glob(path)
        path.include?('*')
      end
    end
  end
end
