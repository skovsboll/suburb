# frozen_string_literal: true

module Suburb
  module DSL
    class File
      def initialize(file_or_ary_or_proc, ins: [], &builder)
        raise 'A file must have a recipe in the form of a do .. end block.' unless builder

        @outs = Array(file_or_ary_or_proc)

        raise 'A file must declare at least one output.' if @outs.empty?

        @ins = Array(ins)

        # raise 'A file must declare at least one input.' if @ins.empty?

        @builder = builder
      end

      attr_reader :outs, :ins, :builder
    end
  end
end
