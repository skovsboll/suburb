build 'out/app.zip', using: ['generated_code/api.rb', 'manifest.md'] do |ins, outs|
  run "zip #{outs[0]} #{ins.join(' ')}"
end

build 'generated_code/api.rb',
      using: 'api.yaml' do |ins, outs|
  File.write(outs[0],
             "require 'sinatra'\n" +
               File.readlines(ins[0]).map(&:strip).map do
                 "get '#{_1}' { [200, {}, 'hello from #{_1}'] }"
               end.join("\n"))
end
