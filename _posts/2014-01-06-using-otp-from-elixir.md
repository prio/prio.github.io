---
layout: post
title: Using OTP from Elixir
---

In this post we will port the TCP RPC server from [Erlang and OTP in Action](http://manning.com/logan/) to Elixir. Elixir is an exciting new language targeting the Erlang VM (BEAM). The TCP RPC server will use the OTP libraries, these are a set of battle tested libraries that allow Erlang programmers to easily create reliable production ready applications. A big part of OTP is supervision trees, we will not use them in this example but will investigate them in a future post. More indept OTP information can be found on the [Erlang site](http://www.erlang.org/doc/design_principles/des_princ.html) or in the excellent [Learn you some erlang for great good](http://learnyousomeerlang.com/what-is-otp) book.

## OTP Behaviours

OTP provides a number of behaviours. You can think of these as contracts (like Java interfaces or abstract base classes) that allow a module to easily hook into typical OTP roles and life cycles. For this example we need only worry about the gen_server behaviour.

## Minimal gen_server implementation

First lets create a new project:

    $ mix new tcprpc

We will ignore most of the files generated for this post. Create a new file called server.ex in lib/tcprpc, this is where we will place our module.

Lets start by implementing the gen_server behaviour and adding some empty callback functions required by the gen_server behaviour. We will also add two functions we will use to start and stop the server. This can be used as a template for future gen_servers you write.

```
defmodule Tcprpc.Server do
  use GenServer.Behaviour

  @doc "Starts the server"
  def start_link() do
    # Delegate to gen_server passing in the current module. ARG will
    # be passed to init
    :gen_server.start_link({ :local, :NAME }, __MODULE__, ARG, [])  
  end

  @doc "Stops the server"
  def stop() do
    :gen_server.cast(:NAME, :stop)
  end

  @doc "Initialize our server"
  def init (ARG) do
  end

  @doc "Implement this multiple times with a different pattern to deal
  with sync messages"
  def handle_call(:message, from, state) do 
  end

  @doc "Implement this multiple times with a different pattern to deal
  with async messages"
  def handle_cast(:message, state) do
  end

  @doc "Handle the server stop message"
  def handle_cast(:stop , state) do
    { :noreply, state }
  end

  @doc "Implement this to handle out of band messages (messages not
  sent using a gen_server call)"
  def handle_info(:message, state) do
  end

end
```

Lets start fleshing out this skeleton to implement our TCP RPC server. Our server will listen on a network port, it will accept an Elixir expression followed by a newline, execute the expression and return its value. First, we will implement the functions that will be our modules external API.

```
  defrecord State, port: nil, lsock: nil, request_count: 0

  def start_link(port) do
    :gen_server.start_link({ :local, :tcprpc }, __MODULE__, port, [])
  end

  def start_link() do
    start_link 1055
  end

  def get_count() do
    :gen_server.call(:tcprpc, :get_count)
  end

  def stop() do
    :gen_server.cast(:tcprpc, :stop)
  end
```

The state record will be used to store information about our server, Elixir data structures are immutable but we can return an updated version from every function call and OTP will store it for us in between calls. start_link/0 and start_link/1 are used to start our server, start_link/0 simply delegates to start_link/1 passing in 1055 as our default port. get_count/0 is a simple wrapper around a sync message send to our server that will return the number of messages we have responded to.

Now lets implement the required gen_server callbacks that we will use to set up our server.

```
  def init (port) do
    { :ok, lsock } = :gen_tcp.listen(port, [{ :active, true }])
    { :ok, State.new(lsock: lsock, port: port), 0 }
  end

  def handle_info(:timeout, state = State[lsock: lsock]) do
    { :ok, _sock } = :gen_tcp.accept lsock
    { :noreply, state }
  end
```

init/0 is called before our server is started by OTP. Here we create a tcp socket on ''port'', add it to our state record and return it. OTP will store it and pass it to our other functions when they are called. Note the last ''0'' value we return, this is our timeout value, here we are telling OTP to timeout immediately, a timeout message will then be sent to our server. In our timeout handling code we listen on the socket for a connection. Forcing the timeout seems a bit hacky to me but apparently it is a common erlang pattern so should be well understood by other erlang/Elixir programmers.

Finally we will implement the message handling functions we require.

```
  def handle_call(:get_count, _from, state) do 
    { :reply, { :ok, state.request_count }, state }
  end

  def handle_cast(:stop , state) do
    { :noreply, state }
  end

  def handle_info({ :tcp, socket, raw_data}, state) do
    do_rpc socket, raw_data
    { :noreply, state.update_request_count(fn(x) -> x + 1 end) }
  end

  def do_rpc(socket, raw_data) do
    try do
      result = Code.eval_string(raw_data)
      :gen_tcp.send(socket, :io_lib.fwrite("~p~n", [result]))
    catch
      error -> :gen_tcp.send(socket, :io_lib.fwrite("~p~n", [error]))
    end
  end
```

We implement a handler for our :get_count message and just return request_count field from our state record and for a :stop async message. The final two functions are where we do most of the work. When we receive data on our socket it is sent to our server "out of band" so we need to implement a handle_info/2 function to deal with this. We call do_rpc/2 passing in the string we received over the socket and then respond updating the request_count field of our state. In do_rpc we eval the string and write the response to the socket.

Now we can test our server. Open a new iex shell in the top level folder of our project and start the server.

    $ iex -S mix
    iex(1)> Tcprpc.Server.start_link
    {:ok, #PID<0.61.0>}
    iex(2)>

Now lets connect to our server using telnet. In another console start a telnet session.

    $ telnet localhost 1055
    Trying 127.0.0.1...
    Connected to localhost.
    Escape character is ''^]''.
    1 + 1
    {2,[]}
    div(10, 2)
    {5,[]}

You can see that when we type in simple Elixir expressions the result is returned to us.

The full module is:

<script src="https://gist.github.com/prio/8290780.js"></script>

## Conclusion

This example is fairly trivial but it does show how to get started with OTP in Elixir (and it shows how easy it is to dynamically eval code in Elixir). Hopefully it also demystifies OTP behaviours somewhat. In a future post I will port the cache example from the OTP book which shows how to use OTP supervisors to monitor and manage your servers.
