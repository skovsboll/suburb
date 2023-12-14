build 'test-result.md', using: ['./spec/*.rb', './src/*.rb'] do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
  sh "cat #{outs[0]}"
end

build('test-result2.md', using: [
        './spec/*.rb',
        '../libary/src/*.rb'
      ]) do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
  sh "cat #{outs[0]}"
end

build('test-result3.md', using: './spec/*.rb') do |_ins, outs|
  rtx "bundle exec rspec --out #{outs[0]}"
  sh "cat #{outs[0]}"
end
