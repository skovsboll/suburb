# frozen_string_literal: true

# Maintains order yet allows keyed access
class UniqueStringSet < Set
  alias << add

  def add(value); end
end
