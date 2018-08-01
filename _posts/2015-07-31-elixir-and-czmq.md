---
layout: post
title: Elixir and ZeroMQ
---

ZeroMQ is an excellent, language agnostic messaging and concurrency library. It can be used to provide non-BEAM based languages with some (but not all!) of the features that we take for granted when writing code in Elixir on the erlang vm. For this post, we will focus on its capabilities as a messaging library. This post gives a brief overview of ZeroMQ but you really should read the excellent [ZeroMQ guide](http://zguide.zeromq.org/page:all) to gain a more complete understanding.

## Sockets

If you have done any socket programming in the past, you will know what a painful process it is to create reliable, scalable programs using them as your base abstraction. And that pain only intensifies if you need to build more sophisticated network topologies. At that point most people give up and reach for sophisticated protocols such as AMQP and intermediary services such as RabbitMQ. RabbitMQ is great, and if it suits your use case you should use it, but sometimes you just don''t want or need the overhead of AMQP and maintaining an install of a third party service. It''s at times like these you should consider ZeroMQ.

## Topologies

ZeroMQ offers a number of different topologies or messaging patterns out of the box. We will describe fours of these briefly in this post. Put first the basics.

The two fundamental ZeroMQ building blocks are the context and socket structures. A context is threadsafe and is used to store the state required by a socket. An application can have multiple contexts. You don''t need to worry about them for these examples, just be aware of their existence. 

A socket is used for communication and is given a certain *type* at creation time. It''s these types that allow us to build different topologies. 

The high level process when writing ZeroMQ code is:

1. Create a context
1. Use that context to create a socket of a certain type 
1. Either bind (if the process is a server) or connect (if the process is a client) using that socket

You are then ready to send and receive messages using the *zstr_send* and *zstr_recv* functions.

### Setup 

**Note:** There are a number of different ZeroMQ wrappers available for Erlang but we are going to use [erlang-czmq](https://github.com/gar1t/erlang-czmq) as it seems to be one of the most actively maintained and stable. The concepts are the same no matter what library you use.

The examples that follow are all simple enough to be run in an iex sessions. Create a new mix project and add czmq to your deps.

```
  defp deps do
    [{:czmq, github: "gar1t/erlang-czmq", compile: "./configure; make"}]
  end
```

As czmq is an erlang library we need to add one more file to help with interop. Create a src directory, and add the [czmq_const.erl file](https://gist.github.com/prio/0d345da03ffc8af71476) I created.

```
$ mkdir src
$ cd src
$ curl -O https://gist.githubusercontent.com/prio/0d345da03ffc8af71476/raw/b937225fbad15253936caa9c42e0e8dfab3b11ed/czmq_const.erl
```

### Pair
The simplest messaging pattern is the **PAIR** pattern. Of all the patterns available its behaviour is that one that most closely matches traditional sockets. The server listens on a port and a client connects to that port. Server and client are then able to send messages to each other. Only one client can connect to the port at one time.

![Pair Pattern](/images/pair.jpg)

**Server session**
```
iex(1)> {:ok, ctx} = :czmq.start_link()
iex(2)> socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_pair)
iex(3)> {:ok, port} = :czmq.zsocket_bind(socket, "tcp://*:5555")
iex(4)> :ok = :czmq.zstr_send(socket, "Hello, client")
iex(5)> {:ok, msg} = :czmq.zstr_recv(socket, [{:timeout, 1000}])
{:ok, ''Hello, server''}
```

**Client session**
```
iex(1)> {:ok, ctx} = :czmq.start_link()
iex(2)> socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_pair)
iex(3)> :ok = :czmq.zsocket_connect(socket, "tcp://localhost:5555")
iex(4)> :czmq.zstr_recv(socket, [{:timeout, 1000}])
{:ok, ''Hello, client''}
iex(5)> :ok = :czmq.zstr_send(socket, "Hello, server")
```

Now that you have seen how simple it is to setup basic two way communication lets take a look at some of the other messaging patterns.

### Client / Server

This is probably the pattern the majority of us are most familiar with. We have one server process that is communicating with multiple clients. The server socket type is **zmq\_rep** (reply) and the client socket type is **zmq\_req** (request).

![](/images/repreq.jpg)

**Server session**

Lets create a basic echo server. Type the following into an iex session.

```
echo = fn(echo, socket) ->
  {:ok, msg} = :czmq.zstr_recv(socket)
  IO.inspect(msg)
  :ok = :czmq.zstr_send(socket, msg)
  echo.(echo, socket)
end

{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_rep)
{:ok, port} = :czmq.zsocket_bind(socket, "tcp://*:5555")
echo.(echo, socket)
```

Now, open one or more iex sessions and start sending requests

**Client session**

```
{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_req)
:ok = :czmq.zsocket_connect(socket, "tcp://localhost:5555")
:czmq.zstr_send(socket, "echo")
:czmq.zstr_recv(socket)
:czmq.zstr_send(socket, "hello")
:czmq.zstr_recv(socket)
```

Notice how easy it is to set up a server that can handle multiple clients. ZeroMQ automatically handles all the book keeping involved in tracking each client and only sends the response to the correct client.

### Publish/Subscribe

In the past when I have required pubsub functionality I have always reached for a dedicated broker such as RabbitMQ, but ZeroMQ allows us to easily create pubsub topologies without the need for a third party broker. The server (publisher/broker) socket type is **zmq\_pub** and the client (subscriber/consumer) type is **zmq\_sub**. A publisher can have multiple subscribers, and a subscriber can subscribe to multiple publishers.

![](/images/pubsub.jpg)

**Server session**

Our server will publish messages (an integer) over one of 4 topics a,b,c or d every second. Subscribers can subscribe to one or more topics of interest.

```
{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_pub)
{:ok, port} = :czmq.zsocket_bind(socket, "tcp://*:5555")
topics = ["_", "a", "b", "c", "d"]
Stream.interval(1_000) |> Enum.map(fn(x) -> 
  topic = Enum.at(topics, :random.uniform(4))
  IO.puts("Sending #{x} to #{topic}")
  :czmq.zstr_send(socket, "#{topic} #{x}")
end)
```

**Client session**

Again, feel free to start up more than one client and have different clients subscribe to the same and different topics.

```
sub = fn(sub, socket) ->
  {:ok, msg} = :czmq.zstr_recv(socket)
  IO.puts(msg)
  sub.(sub, socket)
end
{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_sub)
:ok = :czmq.zsocket_connect(socket, "tcp://localhost:5555")
:czmq.zsocket_set_subscribe(socket, "a" |> String.to_char_list)
sub.(sub, socket)
```

### Push/Pull

The final pattern I will cover is the "Parallel Pipeline" using push/pull socket types. This pattern enables us to push "work" from a ventilator/producer to multiple workers who in turn push their "result" to a sink/collector. 

This example creates a producer that creates a "task" with an integer payload, a group of workers that keep a running total of these integers, and a sink that prints these running totals to the console.

![](/images/pushpull.jpg)

**Producer session**

```
{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_push)
{:ok, port} = :czmq.zsocket_bind(socket, "tcp://*:5555")
Stream.interval(1_000) |> Enum.map(fn(x) -> 
  :czmq.zstr_send(socket, "#{x}")
end)
```

**Worker session**

```
work = fn(work, acc, recv_socket, send_socket) ->
  {:ok, raw} = :czmq.zstr_recv(recv_socket)
  {x, _} = Integer.parse(to_string(raw))
  total = acc + x
  :czmq.zstr_send(send_socket, "#{total}")
  work.(work, total, recv_socket, send_socket)
end
{:ok, ctx} = :czmq.start_link()
recv_socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_pull)
:ok = :czmq.zsocket_connect(recv_socket, "tcp://localhost:5555")
send_socket  = :czmq.zsocket_new(ctx, :czmq_const.zmq_push)
:ok = :czmq.zsocket_connect(send_socket, "tcp://localhost:5556")
work.(work, 0, recv_socket, send_socket)
```

**Collector session**

```
collect = fn(collect, socket) ->
  {:ok, x} = :czmq.zstr_recv(socket)
  IO.puts("Total is #{x}")
  collect.(collect, socket)
end
{:ok, ctx} = :czmq.start_link()
socket = :czmq.zsocket_new(ctx, :czmq_const.zmq_pull)
{:ok, port} = :czmq.zsocket_bind(socket, "tcp://*:5556")
collect.(collect, socket)
```

Notice, that in each session we have to be careful to send strings over the socket and unpack them in the receiver if required. The czmq library does not support sending erlang values such as ints over sockets.

## Conclusion

I hope this helps to get you up and running using ZeroMQ with Elixir. The examples I have shown here are just from the **first** chapter of the the ZeroMQ guide. 

If you are familiar with another programming language try porting one or two of the client examples to it and connect them up to your Elixir server processes.

There really is so much more to ZeroMQ than what I have covered above so please dig into the documentation yourself and learn more about what this excellent library is capable of.
