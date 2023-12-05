class CompositeLog
  def initialize(*logs)
    @logs = logs
  end

  def <<(message)
    @logs.each { |log| log << message }
  end
end
