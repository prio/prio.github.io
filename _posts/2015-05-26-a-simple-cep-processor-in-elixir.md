---
layout: post
title: A CEP Processor in Elixir
---

[CEP](http://en.wikipedia.org/wiki/Complex_event_processing) is the term used to describe systems that process streams of events. In this post, we will use the the data structures created in a [previous post](http://blog.jonharrington.org/simple-sliding-windows-in-elixir/) and a GenEvent server to create a simple CEP processor in Elixir.

### Introduction

The application we are creating is going to recieve stock quotes ("ticks") for different stock symbols and output hourly average prices for each stock. Rather than connect to a live stock feed we will simulate a real time stock feed using random data. Our application design is as follows:

![Application Architecture](/images/GenEventCEP.png)

A GenEvent server receives events and passes them on to any process that has registered as a handler. Every registered handler receives every message (we can''t subscribe to a subset of topics like you can with message queues) so our application has two GenEvent servers, one that recieves input tick events from our "sources" and one that recieves output average events from our workers and passes them on to our "sinks".

Our broker recieves ticks from the input GenEvent server. It then looks up the pid of the process registered for that tick symbol, if it finds it passes the event on to the worker, otherwise it passes it on to the worker factory.

Our worker factory recieves tick events and starts a new worker process to handle the event. Finally, our workers have a timed window data structure that they update every time they recieve an event. They then pass on the 60 minute average to the output GenEvent server. Ok, lets see some code.

(All the code can be found in the [GitHub repo](http://github.com/prio/excep) but I recommended typing the code as you go and only referencing the repo if you get stuck.)

**Note** You will need to add the code from a [previous blog post](http://blog.jonharrington.org/simple-sliding-windows-in-elixir/) and [timex](https://github.com/bitwalker/timex) to your dependencies. 

```
  defp deps do
    [{:window, github: "prio/exwindow"},
     {:timex, github: "bitwalker/timex"}]
  end
```

### A Source

Our source just generates random data to test our application so I won''t go into it in any detail. A real world source would read this data from a feed or a file (if you were doing backtesting for example). It gets passed the input GenEvent process on startup and after every "interval" period, it sends it a tick event.

```
defmodule Source do
  use GenServer
  use Timex

  def start_link(events, interval, symbol) do
    GenServer.start_link(__MODULE__, {events, interval, symbol})
  end

  def price do
    :random.seed(:erlang.now())
    :random.uniform(25) + 100
  end

  def start_timer(state) do
    :erlang.send_after(state.interval, self(),
                       {:tick, {state.symbol, state.time, price()}})
  end

  def init({events, interval, symbol}) do
    state = %{events: events, symbol: symbol,
              time: trunc(Time.to_secs(Time.now)), interval: interval}
    start_timer(state)
    {:ok, state}
  end

  def handle_info(event, state) do
    GenEvent.sync_notify(state.events, event)
    ups = %{ state | time: state.time + state.interval/1000}
    start_timer(ups)
    {:noreply, ups}
  end
end
```

### The Factory

```
defmodule WorkerFactory do
  use GenServer

  def start_link(events) do
    GenServer.start_link(__MODULE__, events)
  end

  def handle_cast(event = {:tick, {symbol, _, _}}, events) do
    {:ok, pid} = Worker.start_link(events, symbol)
    Process.register(pid, symbol)
    GenServer.cast(pid, event)
    {:noreply, events}
  end
end
```

### The Broker

Our broker is the process that will recieve tick events and decide where to send them.

```
defmodule Broker do
  use GenEvent

  def init(factory) do
    {:ok, factory}
  end

  def handle_event(event = {:tick, {symbol, _, _}}, factory) do
    case Process.whereis(symbol) do
      nil -> GenServer.cast(factory, event)
      pid -> GenServer.cast(pid, event)
    end
    {:ok, factory}
  end
end
```

Our Broker recieves the factory process on start up and sends events to it if it can''t find the correct worker process.

### The Workers

Our worker code, will be fairly simple. One startup it creates a new timed window, every time it recieves a raw tick it adds it to the timed window and then sends the hourly average to the ouput GenEvent process.

```
defmodule Worker do
  use GenServer

  def start_link(events, symbol) do
    GenServer.start_link(__MODULE__, {events, symbol})
  end

  def init({events, symbol}) do
    window = Window.timed(60)
    {:ok, %{symbol: symbol, events: events, window: window}}
  end

  def handle_cast({:tick, {symbol, timestamp, value}}, state) do
     w = Window.add(state.window, {timestamp, value})
     avg = Enum.sum(w)/Enum.count(w)
     GenEvent.sync_notify(state.events, {:avg, {symbol, timestamp, avg}})
     {:noreply, %{ state | window: w}}
   end
end
```

### The Sink

Like the source module, our sink module is just a simple dummy useful for development. In real life you would probably use a sink to store the data to a database or a file (or both).

```
defmodule Sink do
  use GenEvent
  use Timex

  def handle_event({:avg, {symbol, timestamp, value}}, factory) do
    date = Date.from(timestamp, :secs) |> DateFormat.format!("{RFC1123}")
    IO.puts("#{date}: #{symbol} average: #{value}")
    {:ok, factory}
  end

  def handle_event(_, factory) do
    {:ok, factory}
  end
end
```

### Tieing it all together

Not that all our code is inplace we need to tied everything together and start our processes, we do this in our Application module.

```
defmodule Cep do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    
    {:ok, input} = GenEvent.start_link
    {:ok, output} = GenEvent.start_link
    {:ok, factory} = WorkerFactory.start_link(output)
    GenEvent.add_handler(input, Broker, factory)
    GenEvent.add_handler(output, Sink, nil)

    children = [
      worker(Source, [input, 5000, :aapl], id: "apple"),
      worker(Source, [input, 5000, :amzn], id: "amazon"),
      worker(Source, [input, 5000, :goog], id: "google"),
    ]

    opts = [strategy: :one_for_one, name: Cep.Supervisor]
    Supervisor.start_link(children, opts)    
  end
end
```

### Running it

Ok, with everything in place we should now be able to test our application. If you run
	
    iex -S mix
    
and after 5 seconds you should start seeing averages being printed to the console. Play around with variables in the application module and see how hard you can make your CPU work :)

## Conclusion

We have seen how using GenEvent servers can decouple consumers/workers and producers. In the future this would allow us to easily add more "tick" consumers without having to modify the existing sources or sinks.
