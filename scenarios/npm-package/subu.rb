# frozen_string_literal: true

build(
  ->(_in_) { 'dist/package.tgz' },
  using: ['dist/package.json', 'version.txt']
) do |ins, _outs|
  rtx "npm pack #{ins[0].dirname}"
end

build 'dist/package.json', using: ['package.json', 'version.txt'] do |ins, outs|
  # replace version number in package.json with the one read from version.txt
  package_json_content = ins[0].read
  version = ins[1].read.strip
  puts "version=#{version}"

  new_package_json = package_json_content.gsub(/"version": ".*"/, "\"version\": \"#{version}\"")

  FileUtils.mkdir_p outs[0].dirname
  File.write outs[0], new_package_json
end

build 'version.txt' do |_, outs|
  sha = rtx 'git rev-parse --short HEAD'
  File.write outs[0], "1.0-#{sha}"
end
