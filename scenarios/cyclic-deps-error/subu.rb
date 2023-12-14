build 'out/A.txt',
      using: 'out/C.txt' do
  run 'touch out/A.txt'
end

build 'out/B.txt',
      using: 'out/A.txt' do
  run 'touch out/B.txt'
end

build 'out/C.txt',
      using: 'out/B.txt' do
  run 'touch out/C.txt'
end
