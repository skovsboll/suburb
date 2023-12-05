# frozen_string_literal: true

require_relative './file'
require_relative '../dependency_graph'

module Suburb
  module DSL
    class Spec
      def files
        @files ||= []
      end

      def builders
        @builders ||= {}
      end

      def file(outs, ins: [], stdout: false, &block)
        files << DSL::File.new(outs, ins:, stdout:, &block)
      end

      def to_dependency_graph(root_path)
        dependencies = Suburb::DependencyGraph.new(root_path)
        files.each do |f|
          f.outs.each do |out|
            add_out(dependencies, out, f.ins, stdout: f.stdout, &f.builder)
          end
        end
        dependencies
      end

      def merge!(other_spec)
        @files += other_spec.files
        @builders.merge!(other_spec.builders)
      end

      def add_out(dependencies, out, ins, stdout: false, &builder)
        case out

        in Proc => proc
          ins
            .map { ::File.expand_path(_1, dependencies.root_path) }
            .map { proc.call(Pathname.new(_1)) }
            .each do |out_|
              dependencies.add_path(out_, stdout:)
              builders[out_] = builder
              ins.each do |in_|
                add_in(dependencies, in_, out_)
              end
            end

        in String => out_
          node = dependencies.add_path(out_, stdout:)
          builders[node.path.to_s] = builder
          ins.each do |in_|
            add_in(dependencies, in_, out_)
          end

        in Array => outs
          outs.each do |out_|
            node = dependencies.add_path(out_, stdout:)
            builders[node.path.to_s] = builder
            ins.each do |in_|
              add_in(dependencies, in_, out_)
            end
          end
        end
      end

      def add_in(dependencies, in_, out)
        path = ::File.expand_path(in_, dependencies.root_path)

        if is_glob(path)
          Dir.glob(path) do |expanded|
            fn = Pathname.new(expanded).basename
            dependencies.add_dependency(out, expanded) if fn != 'subu.rb'
          end
        else
          dependencies.add_dependency(out, path)
        end
      end

      def is_glob(path)
        path.include?('*')
      end
    end
  end
end
