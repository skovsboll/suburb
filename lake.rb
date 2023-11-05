require_relative './node'
require_relative './directed_acyclic_path_graph'

class DSL
  def out(file_or_files)
    @outs << file_or_files
  end

  def in(file_files_or_glob)
    @ins << file_files_or_glob
  end

  def produce(&block)
    @producer = block
  end
end

class Lake
  def run(target_file_path)
    lakefile = find_lakefile(target_file_path) or die("Taget file '#{target_file_path}' not found")
    DSL.new.instance_eval(File.read_all(lakefile))
  end

  def find_lakefile(target_file_path); end

  def die(reason)
    warn reason
    exit 1
  end
end

Lake.new.run(File.expand_path(ARGV[0]))
