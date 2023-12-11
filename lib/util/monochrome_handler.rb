module Suburb
  module Util
    class MonochromeHandler
      attr_reader :level, :output, :label

      def initialize(output: nil, config: nil, label: nil, level: nil)
        @label = label
        @output = output
        @level = level
      end

      def call(event)
        @output.puts event.message.join
      end
    end
  end
end
