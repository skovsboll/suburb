# frozen_string_literal: true

require_relative './file'
require_relative '../graph/dependency_graph'

module Suburb
  module DSL
    class Spec
      def initialize(spec_file)
        @spec_file = Pathname.new(spec_file)
      end

      def root_path
        @spec_file.dirname
      end

      def files
        @files ||= []
      end

      def builders
        @builders ||= {}
      end

      def build(outs, using: [], tags: [], &block)
        files << DSL::File.new(outs, ins: using, tags:, &block)
      end

      def to_dependency_graph
        dependencies = Suburb::Graph::DependencyGraph.new(self)
        files.each do |f|
          f.outs.each do |out|
            add_out(dependencies, out, f.ins, f.tags, &f.builder)
          end
        end
        dependencies
      end

      def merge!(other_spec)
        @files += other_spec.files
        @builders.merge!(other_spec.builders)
      end

      def add_out(dependencies, out, ins, tags, &builder)
        case out
        in Proc => proc
          add_proc_as_out(proc, ins, tags, dependencies, &builder)

        in String => out_
          add_single_out(out_, ins, tags, dependencies, &builder)

        in Array => outs
          outs.each do |out_|
            add_single_out(out_, ins, tags, dependencies, &builder)
          end
        end
      end

      def add_single_out(out_, ins, tags, dependencies, &builder)
        node = dependencies.add_path(out_, tags:)
        builders[node.path.to_s] = builder
        ins.each do |in_|
          add_in(dependencies, in_, out_)
        end
      end

      def add_proc_as_out(proc, ins, tags, dependencies, &builder)
        ins_absolute = ins.map { Pathname.new(::File.expand_path(_1, dependencies.root_path)) }
        Array(proc.call(ins_absolute)).each do |out_|
          add_single_out(out_, ins, tags, dependencies, &builder)
        end
      end

      def add_in(dependencies, in_, out)
        path = ::File.expand_path(in_, dependencies.root_path)

        if glob?(path)
          Dir.glob(path) do |expanded|
            fn = Pathname.new(expanded).basename
            dependencies.add_dependency(out, expanded) if fn != 'subu.rb'
          end
        else
          dependencies.add_dependency(out, path)
        end
      end

      def glob?(path)
        path.include?('*')
      end
    end
  end
end
