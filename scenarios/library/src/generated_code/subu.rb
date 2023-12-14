build 'api.rb', using: 'resources/words' do |ins, outs|
  lines = ins[0].readlines.map { "puts \"#{_1.strip}\"" }
  outs[0].write lines.join("\n")
end
