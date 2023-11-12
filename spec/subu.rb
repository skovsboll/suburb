# frozen_string_literal: true

file 'test-result.md' do
  ins << 'test/*.rb'
  ins << 'src/*.rb'

  run do
    asdf "bundle exec rspec #{ins.join ' '} --out #{outs[0]}"
  end
end
