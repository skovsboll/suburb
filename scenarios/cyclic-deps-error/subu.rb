file 'out/A.txt', ins: 'out/C.txt' do
  sh 'touch out/A.txt'
end

file 'out/B.txt', ins: 'out/A.txt' do
  sh 'touch out/B.txt'
end

file 'out/C.txt', ins: 'out/B.txt' do
  sh 'touch out/C.txt'
end
