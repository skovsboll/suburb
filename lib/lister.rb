require_relative './discovery'

module Suburb
  class Lister
    include Discovery

    def initialize(log) = @log = log

    def run
      sub_specs = Dir.glob('**/subu.rb')
      super_specs = find_all_subu_specs(Dir.cwd)

      specs = (super_specs + sub_specs).map { read_spec(_1) }
      specs.inject(DependencyGraph.new) { |acc, item| acc.merge!(item.to_dependency_graph) }
    end
  end
end
