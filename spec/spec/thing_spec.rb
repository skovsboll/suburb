require 'rspec'
require_relative '../src/thing'

RSpec.describe Thing do
  it 'works' do
    expect(Thing.new.lallerkok).to eq('lallerkok')
  end
end
