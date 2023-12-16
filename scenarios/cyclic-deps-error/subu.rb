build 'out/A.txt',
      using: 'out/C.txt', tags: 'start here' do
  run 'touch out/A.txt'
end

build 'out/B.txt',
      using: 'out/A.txt', tags: 'start here' do
  run 'touch out/B.txt'
end

build 'out/C.txt',
      using: 'out/B.txt', tags: 'start here' do
  run 'touch out/C.txt'
end
