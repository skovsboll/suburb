# frozen_string_literal: true

file 'test-result.md' do
  ins << './spec/*.rb'
  ins << './src/*.rb'

  run do
    asdf "bundle exec rspec #{ins.groups[0].join ' '} --out #{outs[0]}"
  end
end
