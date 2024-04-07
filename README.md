# My Each Method

I must create my own implementation of the `each` method in the `Array` class.

What does each actually do? According to Ruby docs:

1. Iterates over the array elements.
2. When a block is given, it passes each successive array element to the block; returns self.

```rb
a = [:foo, 'bar', 2]
a.each {|element|  puts "#{element.class} #{element}" }
```

**Output**:

```rb
Symbol foo
String bar
Integer 2
```

If no block is given, it returns a new Enumerator:

```rb
a = [:foo, 'bar', 2]

e = a.each
e # => #<Enumerator: [:foo, "bar", 2]:each>
a1 = e.each {|element|  puts "#{element.class} #{element}" }
```

**Output**:

```rb
Symbol foo
String bar
Integer 2
```

## My_each implementation

Looking at the original C code for the each method:

```c
VALUE
rb_ary_each(VALUE ary)
{
    long i;
    ary_verify(ary);
    RETURN_SIZED_ENUMERATOR(ary, 0, 0, ary_enum_length);
    for (i=0; i<RARRAY_LEN(ary); i++) {
        rb_yield(RARRAY_AREF(ary, i));
    }
    return ary;
}
```

1. Define an iterator variable.
2. Loop over the array until all elements have been iterated on.
3. Use `yield` to pass blocks into the method.

What kind of loop should be best here?

- `while` loop.
	- `while i < self.size`
- `until` loop
	- `until i = self.size`

What is `self.size`?

`Self` refers to the current object - the object that is the receiver of the current method call. The specific object it refers to can change depending on where `self` is used.

- Inside an instance method, `self` refers to the instance of the class on which the method is called.
- Inside a class definition but outside any instance methods, `self` refers to the class itself.

`self.size` within an instance method of a class, is calling the `size` method on the current object (`self`). If you're working in the Array class, `self` refers to the array object that the method is called on, and `self.size` is essentially calling the size method on the array, which **returns the number of elements in the array**.

`self.size` in the `my_each` method can be used to determine the length of the array.

**Rough Idea**:
```rb
class Array
	def my_each
		i = 0
		while i < self.size
			yield(self[i])
			i += 1
		end
	end
end
```

This didn't quite work, I just needed to return the original array with `self`.

**Final code**:
```rb
class Array
	def my_each
		i = 0
		while i < self.size
			yield(self[i])
			i += 1
		end
		self # Return the original array
	end
end
```

# my_each_with_index

Should be largely the same as above, but it must be able to keep tract of the current index itself, rather than just the value at that index.

How could I keep track of the index itself?

Well the `i` variable already does that, so how do I use it in the way I want? Just `yield(i)`? No, as it turns out:

```rb
  def my_each_with_index
    i = 0
    while i < self.size
      yield(self[i])
      yield(i)
      i += 1
    end
    self
  end
```

Returning the original array does work, but using a second `yield` like that doesn't solve it.

Turns out, all I have to do is pass the index as a second parameter within the same `yield`. Like so:

**Corrected code**:
```rb
  def my_each_with_index
    i = 0
    while i < self.size
      yield(self[i], i)
      i += 1
    end
    self
  end
```

# my_select implementation

How does the select method work in Ruby?

The `select` method filters based on a given condition. It evaluates each element of the array with the block of code provided. If the block returns `true` for an element, that element is included in the new array that `select` returns, and excluded if `false`.

**Original Ruby Source Code**:
```c
static VALUE
rb_ary_select(VALUE ary)
{
    VALUE result;
    long i;

    RETURN_SIZED_ENUMERATOR(ary, 0, 0, ary_enum_length);
    result = rb_ary_new2(RARRAY_LEN(ary));
    for (i = 0; i < RARRAY_LEN(ary); i++) {
        if (RTEST(rb_yield(RARRAY_AREF(ary, i)))) {
            rb_ary_push(result, rb_ary_elt(ary, i));
        }
    }
    return result;
}
```

First attempt:
```rb
  def my_select
    result = []
    i = 0
    while i < self.size
      if yield(self[i], condition)
        result << self[i]
      end
      i += 1
    end
  end
```

This doesn't work, I need to remember that the condition will be provided by the block that is provided through `yield` anyway, so I don't need to overcomplicate this.

The solution here is to simplify the method:

```rb
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
```

By yielding `self[i]` as above, I'm passing the current element of the collection to the block. Because the block contains the logic or condition that determines whether the element should be included in the result. Evaluating to `true` or `false`.

# my_all? implementation

How does `all?` work?

- Returns true if all elements of `self` meet a given criterion.
- If `self` has no element, returns `true` and argument or block are not used.
- With no block given and no argument, returns `true` if `self` contains only truthy elements, `false` otherwise:

```rb
[0, 1, :foo].all? # => true
[0, nil, 2].all? # => false
[].all? # => true
```

**Ruby Source Code**:
```c
static VALUE
rb_ary_all_p(int argc, VALUE *argv, VALUE ary)
{
    long i, len = RARRAY_LEN(ary);

    rb_check_arity(argc, 0, 1);
    if (!len) return Qtrue;
    if (argc) {
        if (rb_block_given_p()) {
            rb_warn("given block not used");
        }
        for (i = 0; i < RARRAY_LEN(ary); ++i) {
            if (!RTEST(rb_funcall(argv[0], idEqq, 1, RARRAY_AREF(ary, i)))) return Qfalse;
        }
    }
    else if (!rb_block_given_p()) {
        for (i = 0; i < len; ++i) {
            if (!RTEST(RARRAY_AREF(ary, i))) return Qfalse;
        }
    }
    else {
        for (i = 0; i < RARRAY_LEN(ary); ++i) {
            if (!RTEST(rb_yield(RARRAY_AREF(ary, i)))) return Qfalse;
        }
    }
    return Qtrue;
}
```

**Steps Outlined**:
1. If the array is empty, `my_all?` should return `true.` This is a step I can do at the start of the method.
2. When a block is given, check if every element in the array yields a `true` value when passed into the block. If no block is given, just check if every element is truthy on its own. Only `nil` and `false` are falsy values in Ruby.
3. If an element doesn't evaluate as `true`, immediately return `false`. If the loop continues all the way through without return `false`, then it is safe to return `true`.
4. Use `block_given?` to check if a block has been provided, if a block has not been given, then just check the elements return true or not.
5. `my_all?` will either take a block, or use the truthiness of the elements, there's no need to explicitly pass an argument to the method.

1. Check if `self` is empty and return true.
2. Iterate over each element of `self`.
	1. If a block is given, yield each element to the block. If the block returns false, return `false` immediately.
	2. If no block is given, check the truthiness of each element directly. If any element is `false` or `nil`, return `false`.
3. If all elements have been iterated through without return false, return `true`.

This passes all tests:

```rb
  def my_all?
    return true if self == []
    i = 0
    if self.block_given?
      while i < self.size
        return false unless yield(self[i]) == true
        i += 1
      end
      return true
    else
      while i < self.size
        return false unless self[i] == true
          i += 1
      end
      return true
    end
  end
```

*But isn't quite correct*. **Things to correct**:

- `block_given?` shouldn't be called on `self`, it should be used just on its own, to check if a block was passed to `my_all?`.
- The check within the else part of the condition (where there's no given block), should not be checking if the element is literally `true` but rather if the value is not either `false` or `nil`.

**Corrected Code**:

```rb
  def my_all?
    return true if self == []
    i = 0
    if block_given?
      while i < self.size
        return false unless yield(self[i]) == true
        i += 1
      end
      return true
    else
      while i < self.size
        return false if self[i] == false || self[i] == nil
          i += 1
      end
      return true
    end
  end
```

# my_any? implementation

At first I assumed you could just take the `my_all?` method and invert the checks:

```rb
  def my_any?
    return true if self == []
    i = 0
    if block_given?
      while i < self.size
        return true unless yield(self[i]) == false
        i += 1
      end
      return false
    else
      while i < self.size
        return true if self[i] == true
          i += 1
      end
      return false
    end
  end
```

Which actually works, here's the method cleaned up a bit with some `Rubocop` rules taken into account:

```rb
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
```

# my_none? implementation

What does `none?` do?
- Returns `true` if no element of `self` meets a given criterion.
- With no block given and no argument, returns `true` if `self` has no truthy elements, `false` otherwise.

```rb
[nil, false].none? # => true
[nil, 0, false].none? # => false
[].none? # => true
```

Theoretically can just use the `my_all?` code again and invert it.

Here's what I ended up with:

```rb
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
```

It passes both checks.

# my_count implementation

**What does `count` do?**
- Returns the count of elements, based on an argument or block criterion, if given.
- With no argument and no block given, returns the number of elements:
```rb
[0, 1, 2].count                # => 3
{foo: 0, bar: 1, baz: 2}.count # => 3
```
- With argument `object` given, returns the number of elements that are `==` to `object`:
```rb
[0, 1, 2, 1].count(1)           # => 2
```
- With a block given, calls the block with each element and returns the number of elements for which the block returns a truthy value:
```rb
[0, 1, 2, 3].count {|element| element < 2}              # => 2
{foo: 0, bar: 1, baz: 2}.count {|key, value| value < 2} # => 2
```

Based on this, it should be fairly simple.

**Plan**:
1. Check if a block has been given.
2. If a block was given, count the number of elements that match the condition in the block. That is to say, count the number of elements that return true.
3. Else, just count the number of elements.

**Final Code**:
```rb
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
```

This code:
- Immediately returns the number of elements if `block_given?` is `false`.
- Iterates through each element, and if it matches the condition, adds `1` to the `block_matching_elems` variable.
- The `i` iterator is incremented on each run of the loop.
	- Since we already have returned if there is no block given, we just return the `block_matching_elems` variable safely.

# `my_map` implementation

**What does `map` do?**:
- Returns an array of objects returned by the block.
- With a block given, calls the block with successive elements; returns an array of the objects returned by the block:
```rb
(0..4).map {|i| i*i }
#=> [0, 1, 4, 9, 16]

{foo: 0, bar: 1, baz: 2}.map {|key, value| value*2}
# => [0, 2, 4]
```

The `map` method transforms each element from an array according to whatever block you pass to it and returns the transformed elements in a new array.

**Example Usage**:
```rb
friends = ['Sharon', 'Leo', 'Leila', 'Brian', 'Arun']

friends.map { |friend| friend.upcase }
#=> `['SHARON', 'LEO', 'LEILA', 'BRIAN', 'ARUN']`
```

`map` has transformed the `friends` array into each element having uppercase.

**Final Code**:
```rb
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
```

This was actually surprisingly simple, just create an empty array to act as the new transformed array, push elements to that array if they match the block (`yield`). Return the final array at the end.

The `enum_for` part is completely unecessary for the test and I don't fully understand it, but I do know that when a block is not passed to the `map` method, it will return an enumerable, which is what I've done there, using the hints for Ruby in VSCode, either `RubyLSP` or `Solargraph` provided the hints, I'm not sure which exactly.

# `my_inject` implementation

**How does the `inject` method work?**
- Returns an object formed from the operands via either:
	- A method named by `symbol`
	- A block to which each operand is passed.
- With method-name argument `symbol`, combines operands using the method:
```rb
# Sum, without initial_operand.
(1..4).inject(:+)     # => 10
# Sum, with initial_operand.
(1..4).inject(10, :+) # => 20
```
- With a block, passes each operand to the block:
```rb
# Sum of squares, without initial_operand.
(1..4).inject {|sum, n| sum + n*n }    # => 30
# Sum of squares, with initial_operand.
(1..4).inject(2) {|sum, n| sum + n*n } # => 32
```
- If argument `initial_operand` is not given, the operands for `inject` are simply the elements of `self`.

**Example calls and their operands**:
```rb
    (1..4).inject(:+)

        [1, 2, 3, 4].

    (1...4).inject(:+)

        [1, 2, 3].

    ('a'..'d').inject(:+)

        ['a', 'b', 'c', 'd'].

    ('a'...'d').inject(:+)

        ['a', 'b', 'c'].
```

The `inject` method is also known as the `reduce` method.

`inject` is used to accumulate a value across the elements of a collection by applying a binary operation specified by a block or a symbol. It transforms data in a collection into a single value.

At a basic level, `inject` takes two arguments: an initial accumulator value and a block. The block takes two parameters: the accumulator (the accumulated value so far) and an element from the collection. The block's return value becomes the new accumulator value for the next iteration. This process repeats for each element in the collection.

If `inject` is called without an initial value, the first element of the collection is used as the initial accumulator, and iteration starts with the second element.

`inject` can also take a symbol representing a binary operation (like `:+`, `:*`, etc.) instead of a block. In this form, Ruby applies the specified operation to accumulate a value across the elements of the collection.

**Steps to implement**:
1. Decide how to handle both the initial value and the case where no initial value is given.
2. Determine how to apply a block or a symbol to accumulate a value across the collection.
3. Ensure it works with both ranges and arrays, as well as with other enumerable objects.

Another example is to use a block to calculate the product of all numbers in an array:

```rb
[2, 3, 4].inject(1) { |product, n| product * n }
# => 24
```
- This starts with an initial value of `1`.
- The block multiplies the accumulator (`product`) by each element (`n`), so the calculation is `1 * 2 * 3 * 4`, resulting in `24`.

May need to use the `splat` thing for this one.

**What is the splat operator?**
- The splat operator allows you to handle an undefined number of arguments.
- When defining a method, using a splat operator before a parameter name allows that parameter to absorb any number of arguments passed to the method. These arguments are gathered into an array.
```rb
def example_method(*args)
  args.each { |arg| puts arg }
end

example_method(1, 2, 3, 4)
# Outputs:
# 1
# 2
# 3
# 4
```
- In this example, `*args` captures all arguments passed to `example_method` and stores them in an array named `args`
- The splat operator can also *explode* an array into a list of arguments when calling a method. This is useful when you have an array and want to pass its elements as individual arguments to a method.
```rb
def sum(a, b, c)
  a + b + c
end

numbers = [1, 2, 3]
puts sum(*numbers)
# Outputs: 6
```
- For the `my_inject` method, the splat operator would allow accepting a variable number of arguments. This allows me to differentiate between no argumenst being passed and a `nil` argument being explicitly passed.
```rb
def my_inject(*args)
  # args is an array of arguments
  initial_value = args[0] || default_value # You'd define default_value based on your logic
  # Your method logic here...
end
```

**Pseudocode**:
```rb
def my_inject(*args)
  # Determine if initial value is provided and set up accumulator and start index accordingly

  # Iterate over the collection, starting from the appropriate index
    # Update accumulator by applying block or operation to accumulator and current element

  # Return the final accumulator value
end
```

First attempt:
```rb
  def my_inject(*args)
    initial_value = args[0]

    i = 0
    while i < size
    initial_value += self[i]
      i += 1
    end
    
    initial_value
  end
```

Although this passes two tests out of three, it's not correct, here's how to fix it:
- Need to determine if `args[0]` is actually an initial value or potentially an operation symbol (`:+`, `:*`, etc) when a block is not given.
- Start the iteration from the second value if no initial value is provided (using the first element as the initial value in that case).
- If `args.length` is 2, there's likely both an initial value and an operation symbol.
- If `args.length` is 1, there's either an initial value or an operation symbol, the presence of a block should help determine this. If a block is given, `args[0]` is an initial value, if no block is given, `args[0]` is an operation symbol.
- Need to dynamically apply either the block or the operation symbol to the elements. When a block is given, use it to determine how many elements are combined. When an operation symbol is given and no block is present, need to apply this operation to the elements (not currently implemented)
- The setup for `initial_value` doesn't accommodate starting the iteration with the second element if no initial value is provided. Logic is needed to adjust both the `initial_value` and the starting index of the loop based on whether an initial value is actually passed in.

# `my_inject` Implementation Restart
I just wasn't getting it so I took a step back to really try and understand what's going on.

**How does the `inject` method work? (again)**

Ruby's #inject method takes an enumerable collection and accumulates each element into a single value using a block. It can be used in two main ways:

1. With an initial value: `inject(initial_value) {|accumulator, element| block }`
1. Without an initial value: `inject {|accumulator, element| block }`

- `accumulator` is the accumulated value carried over from each step of the iteration.
- `element` is the current element in the collection.

If no initial value is given, Ruby uses the first element of the collection as the initial value and starts the iteration with the second element.

**Example Usage of `#inject`**

Here’s a quick example of using `#inject` to sum an array of numbers:
```rb
[1, 2, 3, 4].inject(0) { |sum, number| sum + number }  #=> 10
```

And without an explicit initial value:
```rb
[1, 2, 3, 4].inject { |sum, number| sum + number }  #=> 10
```

## Solution

```rb
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
```

### The Method Signature

```ruby
def my_inject(accumulator = nil, &block)
```

- **`accumulator`**: This parameter is set to `nil` by default. It serves as the initial value for the accumulation process. If `my_inject` is called without an initial value, `accumulator` starts as `nil`, which signals your method to use the first collection element as the starting value.
- **`&block`**: This captures the block passed to `my_inject`. The block defines how each element of the collection will be combined into a single accumulated value.

### The Iteration

```ruby
self.each do |element|
```

- **`self.each`**: Since we're inside a module that's meant to be included in Enumerable classes, `self` refers to the instance of the collection you're iterating over (e.g., an array). `each` then iterates over each element in this collection.

### Accumulation Logic

```ruby
if accumulator.nil?
  accumulator = element
else
  accumulator = block.call(accumulator, element)
end
```

- **First iteration check (`accumulator.nil?`)**: During the first iteration, if `accumulator` is `nil`, it means no initial value was provided to `my_inject`. Thus, you set `accumulator` to the current element (`element`). This makes the first element of the collection the starting point for accumulation.
  
- **Subsequent iterations**: If `accumulator` is not `nil`, it means you're either on the second (or later) iteration with no initial value provided, or you're on the first iteration with an initial value provided. Here, you call the block with the current `accumulator` and `element` as arguments. The block's return value becomes the new `accumulator`.

This block execution step is where the "injection" happens. The block defines how to combine the accumulated value with the current element, whether that's adding numbers, concatenating strings, or some other operation.

### Returning the Accumulated Value

```ruby
accumulator
```

After iterating through the entire collection, the method returns the final accumulated value.

### Why It Works

Your method effectively abstracts the pattern of iterating over a collection and accumulating a value. By handling the initial value flexibly (either using the one provided or defaulting to the first collection element) and allowing any combination logic through the block, it captures the essence of what `inject`/`reduce` methods do in functional programming paradigms.