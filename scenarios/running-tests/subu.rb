# frozen_string_literal: true

file 'test-result.md', ins: ['./spec/*.rb', './src/*.rb'] do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}", stdout: true
end

file('test-result2.md', ins: ['./spec/*.rb', '../libary/src/*.rb']) do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}; cat #{outs[0]}", stdout: true
end

file('test-result3.md', ins: './spec/*.rb') do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}; cat #{outs[0]}", stdout: true
end
