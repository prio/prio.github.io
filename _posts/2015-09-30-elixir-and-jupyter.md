---
layout: post
title: Elixir and Jupyter
---

When using Python I rely heavily on [Jupyter](https://jupyter.org/) (nee iPython) and now that they are pushing multi-language support I am excited to see what other language communities do with it. In this post I will look at setting it up with an Elixir kernel.

## Setup

First install Jupyer using conda or pip. I recommend using the [Anaconda](http://continuum.io/downloads) distribution and the conda package manager if possible. If using anaconda, a simple

```
$ conda install jupyter
```

should be enough to get you started. 

**Note:** The jupyter binary and its associated commands (jupyter-console, jupyter-notebook etc.) must be on your path otherwise you will get a message such as *jupyter: ''notebook'' is not a Jupyter command*

Next, we need to install and configure the *IElixir* kernel.

```
$ git clone https://github.com/pprzetacznik/IElixir.git
$ cd IElixir
$ mix deps.get
$ MIX_ENV=prod mix compile
$ sh install_script.sh
```
**Note:** IElixir states it needs 1.1.0-dev but I am running it with 1.0.5 and it seems to work fine. (Just edit the mix.exs file if you need to downgrade.)


## Create a notebook

Jupyter provides a number of different interfaces but by far my favorite is the *notebook*, a HTML interface similar to the Mathematica interface. To create a notebook with the IElixir kernel, run

```
$ jupyter notebook
```

Your browser should open the interface (if it doesn''t point it at [http://localhost:8888](http://localhost:8888)). When you select the new menu item, ielxir should be an option

{<1>}![Jupyter Interface](/content/images/2015/09/Screen-Shot-2015-09-08-at-17-01-00.png)

You can now enter any code that you would enter into an iex session, and save that code as a document for reference or editing later.

{<2>}![Jupyter IElixir Kernel](/images/Screen-Shot-2015-09-08-at-17-03-38-1.png)

## Conclusion

It is very easy to set up Jupyter to use Elixir thanks to the great work by [Piotr Przetacznik](https://twitter.com/pprzetacznik). Check it out and see what it can do, its definitely a tool worth having in your toolbox.

