# frozen_string_literal: true

# Hey man, Node is awesome
#
class Node
  attr_accessor :path, :dependencies, :builder

  def initialize(path, &builder)
    @path = Pathname.new(path)
    @dependencies = []
    @builder = builder
  end

  def add_dependency(node)
    raise 'Can not add depenency to one self' if node.path == path
    raise 'Circular dependency or duplicate node detected' if @dependencies.include?(node) || circular_dependency?(node)

    @dependencies << node
  end

  def circular_dependency?(node)
    node.dependencies.include?(self) || node.dependencies.any? { |dep| circular_dependency?(dep) }
  end

  def pp(indent)
    puts "#{''.rjust(indent)}#{@path}"
    @dependencies.each { _1.pp(indent + 4) }
  end
end
