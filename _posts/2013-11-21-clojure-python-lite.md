---
layout: post
title: Clojure-py lite
---

I have been tracking the progress of [clojure-py][1] on and off for the past two years or so but unfortunately it has officially been [dropped by its current maintainer][2]. I know node.js and Clojurescript are Clojures "de-facto" scripting solution but I am more familiar with the Python ecosystem so I was looking forward to being able to use the libraries I know with Clojure. However, on the clojure-py mailing list [Hy][3] was mentioned as a possible alternative so I decided to take a look at Hy and see how close we can get to a Clojure "like" environment on cPython. _Note:_ I am not suggesting anyone use this setup for serious systems, its just a fun exercise.
<!--excerpt-->

## Clojure features

This is not an exhaustive list of Clojure features but they are some
of the ones I use most often and I would like to have something
similar on the cPython platform.

* REPL
* Standard functional and Lisp functions/constructs
* Host interop
* Persistent data structures
* Protocols
* Concurrency constructs: Atoms, Futures, Threads, Refs, Agents
* Laziness
* Clojure niceties: threading macros, 
* Macros
* Meta data
* _Bonus_ Although not a language feature something like the awesome core.async library would be a clincher

OK, lets install hy and see how far we can get.


## REPL

Running `hy` on the command line gives us a REPL. It seems to do paren matching and the up and down arrow keys work like you would expect. Comments in hy start with a ; like Clojure, however writing a comment in the REPL raises a parsing error. Being able to use this from iPython would be very nice, not sure what it would entail however. One for another day.

Verdict: 8/10

## Functional Lisp constructs

Hy seems to have a lot of the standard things you expect in a Lisp. Lets try out some of the basic functions we expect.

```
=> (first [1 2 3 4 5])
1
=> (rest [1 2 3 4 5])
[2, 3, 4, 5]
=> (car [1 2 3 4 5])
1
=> (cdr [1 2 3 4 5])
[2, 3, 4, 5]
=> (take 2 [ 1 2 3 4 ])
<generator object _hy_anon_fn_35 at 0x10d39ab40>
=> (list (take 2 [ 1 2 3 4 ]))
[1, 2]
=> (map inc [1 2 3 4 5])
[2, 3, 4, 5, 6]
=> (import operator)
=> (reduce operator.add [1 2 3 4 5])
15
=> (filter even? [1 2 3 4 5 6 7 8 9 10])
<generator object _hy_anon_fn_12 at 0x10d39ab40>
=> (list (filter even? [1 2 3 4 5 6 7 8 9 10]))
[2, 4, 6, 8, 10]
```

Ah, OK, take and filter are lazy and return a Python generator. Everything works as expected so far. There is also a third party Python library called [toolz][4] whose aim is to build on the functions available in the Python functools and itertools modules. It is heavily influenced by Clojure, "the toolz project generally adheres closely to the API found in the Clojure standard library". Using it from hy is easy:

```
=> (import [toolz.itertoolz.core [concat cons count]])
=> (list (concat [[1 2] [3 4]]))
[1, 2, 3, 4]
=> (list (cons 1 [2 3]))
[1, 2, 3]
=> (count [1 2 3 4 5])
5
```

Using toolz in conjunction with Hy allows us to get most of the basics we would expect. Lets move on to something more interesting.

Verdict: 8/10

## Host interop

Hy claims to be a "pythonic lisp" and its structure is converted to Pythons AST for execution. As you would expect interop works very well. Hy provides Clojure like ''.'' access to methods and an import statement to import Python code. The kwapply function required to supply keyword arguments is a bit ugly however (nitpicking).

Verdict: 9/10

## Persistent data structures

This is a big Clojure advantage, but since Hy is built on Python we are stuck with Pythons mutable data structures by default. There seems to be two third party libraries that provide basic persistent data structures to Python, [pysistence][5] and [pyrsistent][6]. Pysistence has an experimental C module so it may be more performant but it doesn''t seem to be actively maintained. Pysistence was recently released and claims to have been inspired by Clojure. Performance is "generally in the range of 2 - 100 times slower than using the corresponding built in types in Python" but the author claims running on PyPy can greatly improve performance. Since I plan to use this setup for non-production scripts, performance isn''t a deal breaker for me.

```
=> (import [pyrsistent [pvec pmap pset]])
=> (def p1 (pvec 1 2 3))
=> (.append p1 4)
[1, 2, 3, 4]
=> p1
[1, 2, 3]
=> (def pm1 (kwapply (pmap) {:a 1 :b 2}))
=> pm1
{u''\ufdd0:a'': 1, u''\ufdd0:b'': 2}
=> (.todict pm1)
{u''\ufdd0:a'': 1, u''\ufdd0:b'': 2}
=> (:a pm1)
1
=> (.assoc pm1 :c 3)
{u''\ufdd0:a'': 1, u''\ufdd0:c'': 3, u''\ufdd0:b'': 2}
```

Pyrsistent gives us persistent data structures but because its a third party library we lose literal syntax (constructing a map is unwieldy) and it is a very young project.

Verdict: 5/10

## Protocols

Protocols are a fundamental abstraction in Clojure and allow one to write performant polymorphic functions. As part of this setup I am just looking for something to provide me with a way to write polymorphic functions of my own (performance not a concern). As luck would have it [PEP 443][7] was recently approved and, a version of it has been [back-ported to Python 2.7][8]. Singledispatch is a decorator and does not let us group functions together like protocols.

```
=> (import [singledispatch [singledispatch]])
=> (defclass bird [object])
=> (defclass aeroplane [object])
=> (with-decorator singledispatch (defn fly [arg] (print "I fly")))
=> (with-decorator (fly.register bird) (defn _ [self] (print "I fly by flapping")))
=> (with-decorator (fly.register aeroplane) (defn _ [self] (print "I fly using engines")))
=> (fly 1)
I fly
=> (fly (bird))
I fly by flapping
=> (fly (aeroplane))
I fly using engines
```

singledispath is not as powerful as protocols in the broader sense. However it is part of the stdlib from 3.4 onwards and it lets us write polymorphic functions in Hy which is what I was looking for.

Verdict: 8/10

## Next

Ok, this post is already longer than I was expecting and I am not finished yet. I will finish the investigation in my next post.


[1]: https://github.com/halgari/clojure-py "Clojure-py"
[2]: https://groups.google.com/d/msg/clojure-py-dev/HbeNEkIG23U/61rN0wR2qDwJ "Gone"
[3]: http://hylang.org/ "Hy"
[4]: http://toolz.readthedocs.org/ "toolz"
[5]: http://pythonhosted.org/pysistence/ "Pysistence"
[6]: http://pyrsistent.readthedocs.org/en/latest/ "Pyrsistent"
[7]: http://www.python.org/dev/peps/pep-0443/ "PEP 443"
[8]: https://pypi.python.org/pypi/singledispatch "singledispatch"
