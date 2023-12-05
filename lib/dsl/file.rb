# frozen_string_literal: true

module Suburb
  module DSL
    class File
      def initialize(file_or_ary_or_proc, ins: [], stdout: false, &builder)
        @outs = Array(file_or_ary_or_proc)
        @ins = Array(ins)
        @builder = builder
        @stdout = stdout
      end

      attr_reader :outs, :ins, :builder
    end
  end
end
