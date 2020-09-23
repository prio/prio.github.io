---
layout: post
title: Simple Sliding Windows in Elixir
image: /images/Sized.png
---

As part of some research I have been doing I wanted a sliding window data structure and thought it would be interesting to see how to implement custom data structures in Elixir.
<!--excerpt-->

## Custom data structures in Elixir

**Note:** What follows is a very naive implementation, I was more focused on the interface and learning Elixir over performance but I would be very interested in more sophisticated implementations, so please comment.

### A sized sliding window

The first data structure I looked at is a sized sliding Window. The idea here is that we set the Window to a fixed sized and any new items added once the sized as been reached push the oldest item out of the Window.

![A Sized Sliding Window](/images/Sized.png)

Since the data structure is very close to a FIFO queue, we will base our implementation on on the erlang queue data structure.

Lets start off by writing a few tests to define our interface. We are going to call our structure Window.Sized.

```
defmodule Window.SizedTest do
  use ExUnit.Case

  test "i can create a window" do
    w = %Window.Sized{ size: 5 }
    assert w.size == 5
  end

  test "i can add items to window" do
    w =  %Window.Sized{ size: 5 } |>
         Window.Sized.add(1) |>
         Window.Sized.add(2) |>
         Window.Sized.add(3) |>
         Window.Sized.add(4) |>
         Window.Sized.add(5)
    assert :queue.len(w.items) == 5
  end

  test "a window slides" do
    w = %Window.Sized{ size: 5 } |>
         Window.Sized.add(1) |>
         Window.Sized.add(2) |>
         Window.Sized.add(3) |>
         Window.Sized.add(4) |>
         Window.Sized.add(5) |>
         Window.Sized.add(6)
    assert :queue.len(w.items) == 5
  end
end
```

So from experimenting with our tests we can see we can get by with just one function, add, but a user needs to know we are using a queue internally to process whats stored in the Window. This obviously needs to be improved and we will revisit it shortly.

```
defmodule Window.Sized do
  defstruct size: nil, items: :queue.new()

  def add(window = %Window.Sized{size: size, items: items}, item) do
    if :queue.len(items) == size do
      {_, q} = :queue.out_r(items)
      %{ window | items: :queue.in_r(item, q)}
    else
      %{ window | items: :queue.in_r(item, items)}
    end
  end
end
```

### A timed sliding window

A timed sliding Window works similarly to a sized Window, but rather than removing items once a size threshold has been reached we remove items based on a "time".

![A Timed Sliding Window](/images/Timed.png)

To keep things flexible, the definition of "time" and the  resolution that is used is up to the end user. Lets write some tests to tease out the API.

```
defmodule Window.TimedTest do
  use ExUnit.Case

  test "i can create a window" do
    w = %Window.Timed{ duration: 5 }
    assert w.duration == 5
  end

  test "i can add items to window" do
    w =  %Window.Timed{ duration: 5 } |>
         Window.Timed.add({1, 1}) |>
         Window.Timed.add({2, 1}) |>
         Window.Timed.add({3, 1}) |>
         Window.Timed.add({4, 1}) |>
         Window.Timed.add({5, 1})
    assert :queue.len(w.items) == 5
  end

  test "a window slides" do
    w = %Window.Timed{ duration: 5 } |>
        Window.Timed.add({0, 1}) |>
        Window.Timed.add({0, 1}) |>
        Window.Timed.add({3, 1}) |>
        Window.Timed.add({4, 1}) |>
        Window.Timed.add({5, 1}) |>
        Window.Timed.add({6, 1})
    assert :queue.len(w.items) == 4
  end
end
```

Yet again we see we need only an add function (that has the same signature as our Window.Sized), and yet again, we need to exposing the internal queue.

```
defmodule Window.Timed do
  defstruct duration: nil, items: :queue.new()

  def add(window = %Window.Timed{duration: duration, items: items}, {time, item}) do
    start = time - duration
    left = Enum.take_while(:queue.to_list(items), fn({t, _}) -> t > start end)
    %{ window | items: :queue.in_r({time, item}, :queue.from_list(left))}
  end
end
```

## Review (and Refactor)

So far our data structures are very simple, but the API is cumbersome and a user needs to know we are using a queue internally to process the data. It would also be nice for our end user to not care which type of Window they are using when they are writing algorithms to process a Windows data. In an object oriented language we would normally use an interface or base class to solve this, but in Elixir we can use protocols.

First, lets create some tests to help us focus on our API.

```
defmodule WindowTest do
  use ExUnit.Case
  doctest Window

  test "i can create a sized window" do
      w = Window.sized(5)
      assert w.size == 5
  end

  test "i can create a timed window" do
      w = Window.timed(30)
      assert w.duration == 30
  end

  test "a sized window slides" do
    w = Window.sized(5) |>
        Window.add(1) |>
        Window.add(2) |>
        Window.add(3) |>
        Window.add(4) |>
        Window.add(5) |>
        Window.add(6)
    assert Enum.count(w) == 5
  end

  test "a timed window slides" do
    w = Window.timed(5) |>
        Window.add({0, 1}) |>
        Window.add({0, 1}) |>
        Window.add({3, 1}) |>
        Window.add({4, 1}) |>
        Window.add({5, 1}) |>
        Window.add({6, 1})
    assert Enum.sum(w) == 4
  end
end
```

Ok, so not only have we now hidden the Window type once it has been created, we have also decided to make a Window Enumerable. We could have added our own count, sum etc. methods to our Window module, but why bother when Enum provides these functions already, and behaving like an Enumerable means we can take advantage of many other third party Elixir libraries.

So now that we know what we want our Window API to look like, lets create our Windowable protocol.

```
defprotocol Windowable do
    def add(window, item)
    def items(window)
end
```

Our Windowable protocol is very simple, and only requires a structure to implement two functions to participate. The first one of these, add, is obvious but we have also decided to require an items function. This will allow a structure to return its contents while hiding its internal implementation.

Next we will create our Window module, the module that actually works on Windowable structures.

```
defmodule Window do
  def sized(size) do
    %Window.Sized{ size: size }
  end

  def timed(duration) do
    %Window.Timed{ duration: duration }
  end

  def add(window, item) do
    Windowable.add(window, item)
  end
end
```

Next, we need to go back and modify our structures so they behave as Windowable structures. We can also tidy up our unit tests but I will leave that as an exercise to the reader (you can see the tidied up tests in the [github](https://github.com/prio/exwindow) repo).

Lets create an implementation of Windowable for Window.Sized

```
defmodule Window.Sized do
  defstruct size: nil, items: :queue.new()
end

defimpl Windowable, for: Window.Sized do
  def add(window = %Window.Sized{size: size, items: items}, item) do
    if :queue.len(items) == size do
      {_, q} = :queue.out_r(items)
      %{ window | items: :queue.in_r(item, q)}
    else
      %{ window | items: :queue.in_r(item, items)}
    end
  end

  def items(window) do
    :queue.to_list(window.items)
  end
end
```

and for Window.Timed.

```
defmodule Window.Timed do
  defstruct duration: nil, items: :queue.new()
end

defimpl Windowable, for: Window.Timed do

  def add(window = %Window.Timed{duration: duration, items: items}, {time, item}) do
    start = time - duration
    left = Enum.take_while(:queue.to_list(items), fn({t, _}) -> t > start end)
    %{ window | items: :queue.in_r({time, item}, :queue.from_list(left))}
  end

  def items(%Window.Timed{items: items}) do
    Enum.map(:queue.to_list(items), fn {_, i} -> i end)
  end
end
```

and finally we need to create our Enumerable implementation for our two Window types

```
defimpl Enumerable, for: [Window.Sized, Window.Timed] do
  def count(window)    do
    {:ok, length(Window.items(window))}
  end

  def member?(window, value)    do
    {:ok, Enum.member?(Window.items(window), value)}
  end

  def reduce(_,      {:halt, acc}, _fun),   do: {:halted, acc}
  def reduce(window, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(window, &1, fun)}
  def reduce(window = %Window.Sized{ items: items}, {:cont, acc}, fun) do
    if :queue.len(items) == 0 do
      {:done, acc}
    else
      h = :queue.head(items)
      reduce(%{ window | items: :queue.tail(items)}, fun.(h, acc), fun)
    end
  end
  def reduce(window = %Window.Timed{ items: items }, {:cont, acc}, fun) do
    if :queue.len(items) == 0 do
      {:done, acc}
    else
      {_, h} = :queue.head(items)
      reduce(%{ window | items: :queue.tail(items)}, fun.(h, acc), fun)
    end
  end
end
```

## Conclusion
For an Elixir newcomer there is quiet a bit to digest here and I recommend typing in the code yourself to fully understand all the pieces. We have seen how to create simple data structures in Elixir and how to create our own protocols to provide a unified API to these structures. We have also seen how to provide an implementation for the built in Enumerable protocol so our data structures can be used by many standard and third party Elixir functions.

Structures and protocols are very powerful abstraction and provide a great way for us to write reusable code with familiar APIs without the need for classes, interfaces or inheritance.


