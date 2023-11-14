# frozen_string_literal: true

file 'test-result.md', ins: ['./spec/*.rb', './src/*.rb'] do |ins, outs|
  rtx "bundle exec rspec #{ins.groups[0].join ' '} --out #{outs[0]}"
end

file('test-result2.md', ins: [
       './spec/*.rb',
       './src/*.rb'
     ]) do |ins, outs|
  rtx "bundle exec rspec #{ins.groups[0].join ' '} --out #{outs[0]}"
end