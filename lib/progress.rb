require 'tty-progressbar'

module Suburb
  module Progress
    def with_progress(nodes, clean: false, &block)
      bar = TTY::ProgressBar::Multi.new("#{clean ? 'Cleaning' : 'Building'} #{nodes.last.original_path} :bar",
                                        total: nodes.size, bar_format: :crate)
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
