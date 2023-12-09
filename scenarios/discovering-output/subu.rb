file 'tinyusdz/sandbox/emscripten/build/libtinyusdz_static.a', ins: 'tinyusdz/CMakeLists.txt' do
  Dir.chdir 'tinyusdz/sandbox/emscripten' do
    rtx 'emcmake cmake -DCMAKE_BUILD_TYPE=Release -B build -S ../../'
    Dir.chdir 'build' do
      rtx 'make'
    end
  end
end

# The Tiny USDZ git repo
file 'tinyusdz/CMakeLists.txt' do |_ins, outs|
  rtx 'git clone https://github.com/syoyo/tinyusdz.git' unless File.exist? outs[0]
  Dir.chdir 'tinyusdz' do
    rtx 'git pull'
  end
end
