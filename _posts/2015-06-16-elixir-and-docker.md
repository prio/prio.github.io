---
layout: post
title: Elixir, Docker and PG2
---

Over the next few posts I plan to look at ways of making the [CEP processor](http://blog.jonharrington.org/a-simple-cep-processor-in-elixir/) created in the [last post](http://blog.jonharrington.org/a-simple-cep-processor-in-elixir/) distributed. But, before that, I want to take a short diversion and jot down some notes on how to set up Elixir in a docker container and have nodes, running in seperatate containers, communicate with each other.
<!--excerpt-->

## Create your own image (optional)

I am not going to go into any detail on Docker, I''m sure most readers are somewhat familiar with it at this stage, and if you are not there is plenty written elsewhere. 

I am going to create a simple dockerfile to build the image we are going to use, or if you prefer, you can use the image I have pushed to docker hub and skip this step, up to you.

**To build an image yourself**

Create a Dockerfile containing the following

```
FROM ubuntu:14.04
MAINTAINER Your Name <you@your.place>
RUN apt-get install -y wget
RUN wget http://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install -y elixir
CMD ["bash"]
```

Now build the image:

    docker build --tag=jharrington/elixir .


## Start the containers

Now that we have an image, lets start two containers.
   
Open bash in one of the containers, get the containers IP address, and then open an iex console

    $ docker run -t -i --name socrates jharrington/elixir bash
    # ifconfig | awk ''/inet addr/{print substr($2,6)}'' | head -1
    <ip address>
    # iex --name socrates@<ip address> --cookie monster
    iex(1)> Node.self
    :"socrates@<ip address>"
    
Now, open a second terminal, and do the same in the plato container.

    $ docker run -t -i --name plato jharrington/elixir bash
    # ifconfig ...
    ...
    # iex --name plato@<ip address> --cookie monster
    iex(1)> Node.self
    :"plato@<ip address>"
    
Now that we have two nodes, running on two containers, they should be able to ping each other. In socrates type

    iex(1)> Node.ping(:"plato@<ip address>")
        
and in plato type:

    iex(1)> Node.ping(:"socrates@<ip address>")
    :pong


Our nodes can see and communicate with each other. (If a :pang is returned please double check you followed all the steps correctly).

## Process groups (PG2)

Process groups are a mechanism that allow erlang processes, running on one or more nodes, to join a named group. Lets take a look at what this means. Start three containers, socrates, plato and aristotle, and open an iex console in each, setting the name and cookie.

Now, in socrates type:

    iex(1)> :pg2.start()
    iex(2)> :pg2.create(:group)
    iex(3)> :pg2.join(:group, self)    
    iex(4)> :pg2.get_members(:group)
    [#PID<0.64.0>]    
    
We have created a process group and added our self to it. Next in plato type:

    iex(1)> :pg2.start()
    iex(2)> :pg2.create(:group)
    iex(3)> :pg2.join(:group, self)    
    iex(4)> :pg2.get_members(:group)
    [#PID<0.64.0>]    

Oh, so we have created the same group but we can still only see our own pid. We need to tell our nodes about each other. In socrates type:

    iex(5)> Node.ping(:"plato@<ip address>")
    :pong
    iex(6)> :pg2.get_members(:group)    
    [#PID<0.64.0>, #PID<8954.64.0>]    

Now, our nodes have joined and we can see both pids. 

In aristotle type:

    iex(1)> :pg2.start()
    iex(2)> :pg2.create(:group)
    iex(3)> :pg2.join(:group, self)    
    iex(4)> Node.ping(:"plato@<ip address>")
    :pong
    iex(5)> :pg2.get_members(:group)    
    [#PID<8954.64.0>, #PID<9041.64.0>, #PID<0.64.0>]        

Again, our node has joined the cluster and is now visible to all the other nodes. 

In socrates type ctrl-c twice to close the console, and now run get_members again:

    iex(6)> :pg2.get_members(:group)
    [#PID<9041.64.0>, #PID<0.64.0>]       

We can see the pid has automatically been removed from our group, try starting up the console on socrates and running the commands again to watch it re-join.

You can try pausing nodes, killing processes and adding more nodes to have some more fun with this. See a great [post by Christopher Meiklejohn](http://christophermeiklejohn.com/erlang/2013/06/03/erlang-pg2-failure-semantics.html) for more indepth information.


## Conclusion

In this post we have seen how easy it is to build a docker image for our Elixir apps, how to set up communication between two nodes running in different containers, and how we can use pg2 to create named process groups running across multiple nodes. 

I hope this gives you a basic understanding of how to combine these building blocks and has inspired you to go learn more about writing distributed applications using Elixir.
