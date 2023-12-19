require 'tty-progressbar'
require 'pastel'

module Suburb
  module Runtime
    module Progress
      def with_progress(nodes, clean: false, &block)
        pastel = Pastel.new
        green  = pastel.green('▣')
        yellow = pastel.yellow('⬚')

        status = clean ? 'cleaning' : 'building'
        bar = TTY::ProgressBar::Multi.new("#{nodes.last.original_path} #{pastel.dim(status)} :bar",
                                          total: nodes.size,
                                          bar_format: :crate,
                                          complete: green,
                                          incomplete: yellow)
        nodes_with_bars = nodes.map { [_1, bar.register("#{_1.original_path}", total: 1)] }
        nodes_with_bars.each do |node, sub_bar|
          block[node]
          sub_bar.advance
        end
      ensure
        bar.finish
      end
    end
  end
end
