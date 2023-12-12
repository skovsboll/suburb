# frozen_string_literal: true

file(
  'dist/package.tgz', ins: ['dist/package.json']
) do |ins, outs|
  filename, = rtx "npm pack #{ins[0].dirname}"
  sh "cp #{filename.strip} #{outs[0]}"
end

file 'dist/package.json', ins: ['package.json', 'version.txt'] do |ins, outs|
  # replace version number in package.json with the one read from version.txt
  package_json_content = ins[0].read
  version = ins[1].read.strip
  puts "version=#{version}"

  new_package_json = package_json_content.gsub(/"version": ".*"/, "\"version\": \"#{version}\"")

  FileUtils.mkdir_p outs[0].dirname
  File.write outs[0], new_package_json
end

file 'version.txt' do |_, outs|
  sha, = rtx 'git rev-parse --short HEAD'
  File.write outs[0], "1.0-#{sha}"
end
