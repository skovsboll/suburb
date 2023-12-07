module Suburb
  module Debug
    def pp_nodes(nodes)
      if nodes.is_a? Hash
        pp nodes.map { [_2.path.to_s, _2.dependencies.map(&:path).map(&:to_s)] }.to_h
      else
        pp nodes.map { [_1.path.to_s, _1.dependencies.map(&:path).map(&:to_s)] }.to_h
      end
    end
  end
end
