# frozen_string_literal: true

module Suburb
  module DSL
    class File
      def initialize(file_or_ary_or_proc, ins: [], tags: [], &builder)
        raise Runtime::RuntimeError, 'A file must have a recipe in the form of a do .. end block.' unless builder

        @outs = Array(file_or_ary_or_proc)

        raise Runtime::RuntimeError, 'A file must declare at least one output.' if @outs.empty?

        @ins = Array(ins)
        @builder = builder
        @tags = Array(tags)
      end

      attr_reader :outs, :ins, :builder, :tags
    end
  end
end
