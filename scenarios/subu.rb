# frozen_string_literal: true

file 'test-result.md', ins: ['./spec/*.rb', './src/*.rb'] do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
end

file('test-result2.md', ins: [
       './spec/*.rb',
       './src/*.rb'
     ]) do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
end

file('test-result3.md', ins: './spec/*.rb') do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
end

file 'app.zip', ins: 'src/generated_code/api.rb' do |ins, outs|
  rtx "zip #{outs[0]} #{ins[0]}"
end
