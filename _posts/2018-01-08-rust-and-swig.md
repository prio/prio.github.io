---
layout: post
published: false
title: Rust and Swig
---

For a personal project I am working on I wanted to create Python bindings to a Rust library I am creating. The first port of call was Milksnake and I wrote a Python wrapper to make it nicer to consume. However, a few weeks later I wanted wrappers for a few more languages and rather than create each one individually I decided to see if I could use a tried and trusted tool like Swig. What follows is a short tutorial on how to use Swig to create bindings for a rust library.

## The rmath library

We will write a simple library with one function that takes two integers and adds them, returning the sum. First we create a new Rust crate.

```
cargo init --lib rmath
```

We add the following function to `src/lib.rs` and edit the test:

```
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
```


And now run cargo test to make sure it all works.

### The rmath C library

Now we need to expose this as a C API. We could edit our sum function so it is C compatible but it would make usage from rust awkward. We could also just add another function to this crate that exposes a C compatible version but if you are creating a real library a nicer way to do it is to create a new crate that contains the C api.

Run

```
cargo init —-lib rmath-c
```

We need to update our Cargo.toml file with our dependencies and we need to tell cargo we want to build a C shared library.

```
[lib]
name = "rmath_c"
crate-type = ["cdylib"]

[build-dependencies]
cbindgen = "0.6"

[dependencies]
rmath = { version = "0.1.0", path = ".." }
libc = "0.2"
```

Now, we will create a C “friendly” function in `src/lib.rs` that we use to expose our sum function.

```
extern crate libc;
extern crate rmath;

use libc::{c_int};

#[no_mangle]
pub extern "C" fn sum(a: c_int, b: c_int) -> c_int {
  a + b
}
```

Next build the crate and make sure it compiles. You should now have a shared library in `target/debug/` (called librmath_c.dylib on OS X).

Now we need to use cbindgen to create a C header file. Create a new file called `build.rs` in the same folder as your Cargo.toml file.

```
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
```

And add `build = "build.rs"` to the package section of your Cargo.toml file.

```
[package]
name = "rmath-c"
build = "build.rs"
```

Running cargo build again should create `target/rmath.h`.

### Swig

Finally, we need to use Swig to create a Python binding. First install Swig using the instructions on its website.

Then create a swig file called `rmath.i` and add the following:

```
%module rmath
%{
#include "rmath.h"
%}
%include "rmath.h"
```

This tells Swig our module is called rmath, we want to include rmath.h and we want to wrap the functions defined in rmath.h. Any further Swig Now we need to build the Python package, these commands can be added to a Makefile if desired.


```
cp target/debug/librmath_c.dylib target/librmath.so
cp rmath.i target/
swig -python -outdir target target/rmath.i
gcc -fPIC -Wno-register -Wall -c -o target/rmath_wrap.o target/rmath_wrap.c -Itarget/ `python2-config --includes`
gcc -Wno-deprecated-register -shared -o target/_rmath.so target/rmath_wrap.o -Ltarget/ -lrmath -lpython
```

Now we cd into the target folder and fire up Python:

```
jonathan@euclid:~/blog/rmath/rmath-c/target$ python
Python 2.7.14 |Anaconda, Inc.| (default, Oct 5 2017, 02:28:52)
[GCC 4.2.1 Compatible Clang 4.0.1 (tags/RELEASE_401/final)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import rmath
Fatal Python error: PyThreadState_Get: no current thread
Abort trap: 6
```

Oh! If you get an error like this it means the version of Python you linked against is different to the one you are running. By specifying '-lpython' it is likely you linked against your default system Python rather than any other install, so running try again using your system Python.

```
Python 2.7.10 (default, Feb 7 2017, 00:08:15)
[GCC 4.2.1 Compatible Apple LLVM 8.0.0 (clang-800.0.34)] on darwin
Type "help", "copyright", "credits" or "license" for more information.
>>> import rmath
>>> rmath.sum(2, 3)
5
```

Excellent. You can now package up `rmath.py` and `_rmath.so` and use your Rust library from Python.
