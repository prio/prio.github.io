---
layout: post
title: Rust and Swig
cover: images/rust.jpeg
navigation: True
class: post-template
subclass: 'post'
---

For a personal project I am working on I wanted to create Python bindings to a Rust library I am creating. The first port of call was [Milksnake][1] and I wrote a Python wrapper to make it nicer to consume. However, a few weeks later I wanted wrappers for a few more languages and rather than create each one individually I decided to see if I could use a tried and trusted tool like [Swig][2]. What follows is a short tutorial on how to use Swig to create bindings for a Rust library.
<!--excerpt-->

## The rmath library

We will write a simple library with one function that takes two integers and adds them, returning the sum. First we create a new Rust crate.

{% highlight shell %}
cargo init --lib rmath
{% endhighlight %}

We add the following function to `src/lib.rs` and edit the test:

{% highlight Rust %}
pub fn sum(a: u32, b: u32) -> u32 {
  a + b
}

#[cfg(test)]
mod tests {
    use super::*;
    
    #[test]
    fn it_works() {
        assert_eq!(sum(2, 2), 4);
    }
}
{% endhighlight %}


And now run cargo test to make sure it all works.

### The rmath C library

Now we need to expose this as a C API. We could edit our sum function so it is C compatible but it would make usage from Rust awkward. We could also just add another function to this crate that exposes a C compatible version but if you are creating a real library a nicer way to do it is to create a new crate that contains the C api.

Run

{% highlight shell %}
cargo init —-lib rmath-c
{% endhighlight %}

to create the crate for our C API. We need to update our Cargo.toml file with our dependencies and we need to tell cargo we want to build a C shared library.

{% highlight toml %}
[lib]
name = "rmath_c"
crate-type = ["cdylib"]

[build-dependencies]
cbindgen = "0.6"

[dependencies]
rmath = { version = "0.1.0", path = ".." }
libc = "0.2"
{% endhighlight %}

Now, we will create a C “friendly” function in `src/lib.rs` that we use to expose our sum function.

{% highlight Rust %}
extern crate libc;
extern crate rmath;

use libc::{c_int};

#[no_mangle]
pub extern "C" fn sum(a: c_int, b: c_int) -> c_int {
    rmath::sum(a as u32, b as u32) as i32    
}
{% endhighlight %}

Next build the crate and make sure it compiles. You should now have a shared library in `target/debug/` (called librmath_c.dylib on OS X).

Now we need to use cbindgen to create a C header file. Create a new file called `build.rs` in the same folder as your Cargo.toml file.

{% highlight Rust %}
extern crate cbindgen;

use std::env;

fn main() {
    let crate_dir = env::var("CARGO_MANIFEST_DIR").unwrap();
    let mut config: cbindgen::Config = Default::default();
    config.language = cbindgen::Language::C;
    cbindgen::generate_with_config(&crate_dir, config)
      .unwrap()
      .write_to_file("target/rmath.h");
}
{% endhighlight %}

And add `build = "build.rs"` to the package section of your Cargo.toml file.

{% highlight toml %}
[package]
name = "rmath-c"
build = "build.rs"
{% endhighlight %}

Running cargo build again should create `target/rmath.h`.

### Swig

Finally, we will use Swig to create a Python and r bindings. First install Swig using the instructions on its [website][2].

Then create a swig file called `rmath.i` and add the following:

{% highlight c %}
%module rmath
%{
#include "rmath.h"
%}
%include "rmath.h"
{% endhighlight %}

This tells Swig our module is called rmath, we want to include rmath.h and we want to wrap the functions defined in rmath.h. 

First we will build the Python package, these commands can be added to a Makefile if desired.

{% highlight shell %}
mkdir python
cp target/debug/librmath_c.dylib python/librmath.so
cp rmath.i python/
swig -python -outdir python python/rmath.i
gcc -fPIC -Wno-register -Wall -c -o python/rmath_wrap.o python/rmath_wrap.c -Ipython/ `python2-config --includes`
gcc -Wno-deprecated-register -shared -o python/_rmath.so python/rmath_wrap.o -Lpython/ -lrmath -lpython
{% endhighlight %}

Now we cd into the python folder and fire up Python:

{% highlight shell %}
Python 2.7.14 |Anaconda, Inc.| (default, Oct 5 2017, 02:28:52)
[GCC 4.2.1 Compatible Clang 4.0.1 (tags/RELEASE_401/final)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import rmath
Fatal Python error: PyThreadState_Get: no current thread
Abort trap: 6
{% endhighlight %}

Oh! If you get an error like this it means the version of Python you linked against is different to the one you are running. By specifying '-lpython' it is likely you linked against your default system Python rather than another install that may be in your path, so we you may need to try again using your system Python.

{% highlight shell %}
Python 2.7.10 (default, Feb 7 2017, 00:08:15)
[GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.34)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import rmath
>>> rmath.sum(2, 3)
5
{% endhighlight %}

Excellent. You can now package up `rmath.py` and `_rmath.so` and use your Rust library from Python.

Finally, we will use the same swig file to create r bindings.

{% highlight shell %}
mkdir r
cp target/debug/librmath_c.dylib r/librmath.so
cp target/rmath.h r/rmath.h
cp rmath.i r/
swig -r -outdir r r/rmath.i	
PKG_LIBS="r/librmath.so" R CMD SHLIB r/rmath_wrap.c -o r/rmath.so
{% endhighlight %}

Now if we cd into the r folder and fire up the r interperator:

{% highlight shell %}
R version 3.5.1 (2018-07-02) -- "Feather Spray"
Type 'q()' to quit R.

> dyn.load(paste("rmath", .Platform$dynlib.ext, sep=""))
> source("rmath.R")
> cacheMetaData(1)
> sum(88, 99)
[1] 187
{% endhighlight %}

we can use the same Rust function.

### Conclusion

Rust is a very promising language and as we have seen, using mature tools such as Swig it is very easy to tip your toe in the water and start including Rust libraries in your existing Python and r projects where you may need a perfromance boast or wish to take advantage of Rusts type safety and [fearless concurrency][3]. The full project can be downloaded from [github][4].

[1]: https://github.com/getsentry/milksnake "Milksnake"
[2]: http://swig.org/ "SWIG"
[3]: https://blog.Rust-lang.org/2015/04/10/Fearless-Concurrency.html "Fearless Concurrency"
[4]: https://github.com/prio/rmath "rmath github repo"