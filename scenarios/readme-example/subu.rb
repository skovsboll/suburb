file 'out/app.zip', ins: ['generated_code/api.rb', 'manifest.md'] do |ins, outs|
  sh "zip #{outs[0]} #{ins.join(' ')}"
end

file 'generated_code/api.rb', ins: 'api.yaml' do |ins, outs|
  File.write(outs[0], 
    "require 'sinatra'\n" +
      File.readlines(ins[0]).map(&:strip).map { 
        "get '#{_1}' { [200, {}, 'hello from #{_1}'] }" 
      }.join("\n")
  )
end
