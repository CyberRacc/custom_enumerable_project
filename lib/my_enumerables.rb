module Enumerable
  # Your code goes here
  def my_each_with_index
    i = 0
    while i < self.size
      yield(self[i], i)
      i += 1
    end
    self
  end

  def my_select
    result = []
    i = 0
    while i < self.size
      if yield(self[i])
        result << self[i]
      end
      i += 1
    end
    result
  end
end

# You will first have to define my_each
# on the Array class. Methods defined in
# your enumerable module will have access
# to this method
class Array
  def my_each
    i = 0
    while i < self.size
      yield(self[i])
      i += 1
    end
    self
  end
end
