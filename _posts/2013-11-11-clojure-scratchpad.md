---
layout: post
title: My Clojure Scratchpad
---

When I want to do a quick calculation or perform a few one off commands that are beyond my bash knowledge I normally reach for Python. <!--excerpt--> My work flow is

    $ workon scratch
    $ ipython
    >>> !pip install pkg # if required
    >>> import pkg

The reason I still reflexively go for Python is mostly down to start up time (and how easy it is to manage environments using virtualenv and pip). I wanted to see if I could set up something as smooth in Clojure using the newly released [Grenchman][1] from Phil Hagelberg.

## Speedy start up time

Firstly, environment management in Clojure work very differently to Python so to quickly jump to a folder containing a Leiningen scratch project I figured my best bet is bash. First create a project you plan to use as your scratch pad.

    $ lein new scratch

The next thing to tackle is the start up time of the repl. Install grench using the instructions on its [homepage][1] and create a ~/.nrepl-port file containing a port number which also needs to be added to the scratch project.clj file. So put

    17652

into ~/.nrepl-port and add

    :repl-options {:port 17652} 

to the project.clj

Now if you run 

    $ lein trampoline repl

in one terminal window running

    $ grench repl

in another should start a clojure repl immediately.

## Package management

Being able to add packages automatically to a virtualenv in iPython is very useful, to emulate this behaviour in a clojure repl we can use leiningen and lein-exec. First add

    [lein-exec "0.3.1"]
    [leiningen "2.3.3"]]

to the scratch project.clj *:dependencies* and then run

    $ lein deps

to download them. Now, restart the repl you created earlier and run 

    $ grench repl

again to open a repl. We can now install dependencies and use them from the repl

	user=> (use ''[leiningen.exec :only  (deps)])
	nil
	user=> (deps ''[[digest "1.4.3"]])
	{[org.clojure/clojure "1.4.0"] nil, [digest "1.4.3"] #{[org.clojure/clojure "1.4.0"]}}
	user=> (require ''digest)
	nil
	user=> (digest/md5 "deps-on-the-fly")
	"db982bbb87ec99015e91049312c1d65c"

## Tiding it all up

So now that we have the basics in place we need a repl for our scratch project to start up at boot time or login time and import deps at init time. Your final project.clj file should look like the following

{% highlight clojure %}
	(defproject scratch "0.1.0-SNAPSHOT"
	  :description "FIXME: write description"
	  :url "http://example.com/FIXME"
	  :license {:name "Eclipse Public License"
   		        :url "http://www.eclipse.org/legal/epl-v10.html"}
	  :dependencies [[org.clojure/clojure "1.5.1"]
   		             [lein-exec "0.3.1"]
       	             [leiningen "2.3.3"]]
	  :repl-options {:port 17652
   		             :init (use ''[leiningen.exec :only  (deps)])})
{% endhighlight %}

How you start a repl automatically will depend on the operating system you use. I use OS X so the easiest way I could find is to create the following Applescript, export it as an app and add it to my login items.

    tell application "Terminal"
        do shell script "cd /Users/jonathan/.clojurescratch/scratch && /usr/local/bin/lein trampoline repl :headless"
    end tell


[1]: http://leiningen.org/grench.html "Grenchman Homepage"
