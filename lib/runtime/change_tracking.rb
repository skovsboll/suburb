require 'set'
require 'fileutils'
require_relative 'dependency_sorting'

module Suburb
  module Runtime
    class ChangeTracking
      include Runtime::DependencySorting

      attr_reader :ins_to_watch,
                  :outs_to_watch,
                  :files_to_watch

      def initialize(graph, node, deps_to_build)
        @deps_to_build = Set.new(deps_to_build.map { _1.path.to_s })
        @ins_to_watch = Set.new(transitive_ins(graph, node).map { _1.path.to_s })
        @outs_to_watch = Set.new(transitive_outs(graph, node).map { _1.path.to_s })

        @declared_files = @deps_to_build & (@ins_to_watch | @outs_to_watch)
        @declared_files_before = times_per_file(@declared_files)

        @non_declared_files = Set.new(Dir.glob(node.path.dirname + '**')) - @declared_files
        @non_declared_files_before = times_per_file(@non_declared_files)
      end

      def changes
        declared_files_after = times_per_file(@declared_files)

        non_existing_ins = @ins_to_watch.select do |path|
          @declared_files_before[path].nil?
        end

        non_created_outs = @outs_to_watch.select do |path|
          declared_files_after[path].nil?
        end

        non_read_ins = @ins_to_watch.select do |path|
          declared_files_after.dig(path, :atime) == @declared_files_before.dig(path, :atime)
        end

        non_modified_outs = @outs_to_watch.select do |path|
          declared_files_after.dig(path, :mtime) == @declared_files_before.dig(path, :mtime)
        end

        non_declared_files_after = times_per_file(@non_declared_files)
        non_declared_files_read = @non_declared_files.select do |path|
          non_declared_files_after.dig(path, :atime) == @non_declared_files_before.dig(path, :atime)
        end

        non_declared_files_modified = @non_declared_files.select do |path|
          non_declared_files_after.dig(path, :mtime) == @non_declared_files_before.dig(path, :mtime)
        end

        { non_read_ins:,
          non_modified_outs:,
          non_declared_files_read:,
          non_declared_files_modified:,
          non_created_outs:,
          non_existing_ins: }
      end

      private

      def times_per_file(paths)
        paths.select { File.exist? _1 }.map do |path|
          [path,
           { mtime: File.mtime(path),
             atime: File.atime(path) }]
        end.to_h
      end
    end
  end
end
