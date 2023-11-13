# frozen_string_literal: true

# file(->(ins) { "package-#{ins['version.txt'].read_all}.tgz" }) do
#   ins << 'dist/package.json'

#   run { |_, _outs| asdf "npm pack #{outs.only}" }
#   # asdf "npm pack #{outs.only}"
# end

file 'dist/package.json' do
  ins << 'package.json'
  ins << 'version.txt'

  run do |ins, outs|
    # replace version number in package.json with the one read from version.txt
    package_json_content = File.read_all ins[0].path
    version = File.read_all(ins[1])

    new_package_json = package_json_content.gsub(/"version": ".*"/, "\"version\": \"#{version}\"")

    File.write outs.only.path, new_package_json
  end
end

file 'version.txt' do
  run do |_ins, outs|
    sha = exec 'git rev-parse --short HEAD'
    File.write outs[0].path, "1.0-#{sha}"
  end
end
