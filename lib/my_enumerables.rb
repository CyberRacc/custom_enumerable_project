# frozen_string_literal: true

# My own implementation of the Enumerable module

# rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Lint/MissingCopEnableDirective, Metrics/MethodLength
module Enumerable
  # Your code goes here
  def my_each_with_index
    i = 0
    while i < size
      yield(self[i], i)
      i += 1
    end
    self
  end

  def my_select
    result = []
    i = 0
    while i < size
      result << self[i] if yield(self[i])
      i += 1
    end
    result
  end

  def my_all?
    return true if self == []

    i = 0
    if block_given?
      while i < size
        return false unless yield(self[i]) == true

        i += 1
      end
    else
      while i < size
        return false if self[i] == false || self[i].nil?

        i += 1
      end
    end
    true
  end

  def my_any?
    return false if self == []

    i = 0
    if block_given?
      while i < size
        return true unless yield(self[i]) == false || yield(self[i]).nil?

        i += 1
      end
    else
      while i < size
        return true if self[i]

        i += 1
      end
    end
    false
  end

  def my_none?
    i = 0
    if block_given?
      while i < size
        # returns true unless the block
        return false if yield(self[i])

        i += 1
      end
    else
      while i < size
        return false if self[i]

        i += 1
      end
    end
    true
  end

  def my_count
    block_matching_elems = 0
    i = 0
    return size unless block_given?

    while i < size
      block_matching_elems += 1 if yield(self[i])
      i += 1
    end

    block_matching_elems
  end

  def my_map
    # If no block is provided, my_map will return an enumerator, it will not perform any transformations.
    return enum_for(:my_map) unless block_given?

    transformed_array = []

    # Iterates over the elements, performing whatever the block has defined.
    i = 0
    while i < size
      transformed_array << yield(self[i])
      i += 1
    end
    transformed_array
  end

  def my_inject(accumulator = nil, &block)
    self.each do |element|
      if accumulator.nil?
        accumulator = element
      else
        accumulator = block.call(accumulator, element)
      end
    end
    accumulator
  end
end

# You will first have to define my_each
# on the Array class. Methods defined in
# your enumerable module will have access
# to this method
class Array
  def my_each
    i = 0
    while i < size
      yield(self[i])
      i += 1
    end
    self
  end
end
