# frozen_string_literal: true

# file(->(ins) { "package-#{ins['version.txt'].read_all}.tgz" }, ins: ['dist/package.json']) do |_, outs|
#   rtx "npm pack #{outs[0]}"
# end

file 'dist/package.json', ins: ['package.json', 'version.txt'] do |ins, outs|
  # replace version number in package.json with the one read from version.txt
  package_json_content = File.read_all ins[0]
  version = File.read_all(ins[1])

  new_package_json = package_json_content.gsub(/"version": ".*"/, "\"version\": \"#{version}\"")

  File.write outs[0], new_package_json
end

file 'version.txt' do |_, outs|
  sha = rtx 'git rev-parse --short HEAD'
  File.write outs[0], "1.0-#{sha}"
end
