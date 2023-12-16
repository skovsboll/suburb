# frozen_string_literal: true

build 'app.zip',
      using: '../library/src/generated_code/api.rb',
      tags: '' do |ins, outs|
  rtx "zip #{outs[0]} #{ins[0]}"
end
