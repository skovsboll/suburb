# frozen_string_literal: true

file 'app.zip', ins: '../library/src/generated_code/api.rb' do |ins, outs|
  rtx "zip #{outs[0]} #{ins[0]}"
end
