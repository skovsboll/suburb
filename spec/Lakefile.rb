file 'test-result.md' do
	in 'test/*.rb'
	in 'src/*.rb'
	exec :asdf, :bundle

	produce do |ins, outs|
		sh "bundle exec rspec #{ins.join ' '} --out #{outs[0]}"
	end
end


file(-> ins { "package-#{ins['version.txt'].read_all}.tgz" }) do
	in 'version.txt'

	exec :asdf, :bundle
	sh ''
end


file 'version.txt' do |outs|
	sh ''
	File.write outs[0], ""
end