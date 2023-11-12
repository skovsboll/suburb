# frozen_string_literal: true

File.readlines('/usr/share/dict/words').map(&:strip).filter { |word| word.end_with? 'rb' }.each { puts _1 }
