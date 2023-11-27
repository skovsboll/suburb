# frozen_string_literal: true

file 'api.rb', ins: 'words' do |ins,outs|
	lines = ins[0].read_lines.map { "puts \"#{_1}\"" }
	outs[0].write lines.join("\n")
end
