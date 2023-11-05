class Node
  attr_accessor :path, :dependencies

  def initialize(path)
    @path = path
    @dependencies = []
  end

  def add_dependency(node)
    if !@dependencies.include?(node) && !circular_dependency?(node)
      @dependencies << node
    else
      raise "Circular dependency or duplicate node detected"
    end
  end

  def circular_dependency?(node)
    node.dependencies.include?(self) || node.dependencies.any? { |dep| circular_dependency?(dep) }
  end
end

