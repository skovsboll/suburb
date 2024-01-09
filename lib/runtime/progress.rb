require 'tty-progressbar'
require 'pastel'

module Suburb
  module Runtime
    module Progress
      def with_progress(nodes, clean: false, &block)
        pastel = Pastel.new
        green  = pastel.green('●')
        yellow = pastel.yellow('○')
        status = clean ? 'cleaning' : 'building'
        main_path = nodes.last.path.relative_path_from(Pathname.pwd)
        bar = TTY::ProgressBar::Multi.new("#{main_path} #{pastel.dim(status)} :bar",
                                          total: nodes.size,
                                          bar_format: :crate,
                                          complete: green,
                                          incomplete: yellow)
        nodes_with_bars = nodes.map do
          path = _1.path.relative_path_from(Pathname.pwd)
          [_1, bar.register("#{path}", total: 1)]
        end
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
