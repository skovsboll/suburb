module Suburb
  module TimeFormatting
    def format_elapsed(start_time, end_time)
      elapsed = end_time - start_time
      if elapsed < 1.0
        "#{format('%.0f', (elapsed * 1000))} ms"
      elsif elapsed < 60
        "#{'%.0f' % elapsed} seconds"
      else
        "#{format('%.0f', (elapsed / 60))}:{'%.0f' % (elapsed % 60)}"
      end
    end
  end
end
