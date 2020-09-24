---
layout: post
title: Creating an Excel Add-in in D
cover: images/ged048.jpg
navigation: True
class: post-template
subclass: 'post'
---

Next in my series on Excel add-ins is integration with the [D][1] programming language.

# Introduction

"D is a general-purpose programming language with static typing, systems-level access, and C-like syntax. With the D Programming Language, write fast, read fast, and run fast" (D website)

D is often a language I have seen mentioned but its not one I am overly familiar with. I believe the first time I landed on the website it was not published under an open source licence, which at the time was a deal breaker for me. It has since become more open and in recent years has been merged into GCC. For this reason I felt it was worth another look.



# Excel-D

Rather than wrap the code in an Excel-DNA add-in like I did with the [Rust][2] example, a D wrapper around the Excel SDK called [Excel-D][3] exists. A tool called [autowrap](https://github.com/symmetryinvestments/autowrap) also exists which can wrap D code for Python, Excel and C# so an Excel-DNA approach could also be taken. In this post I will use the fully native approach.



## Project

The standard D build tool is called [dub](https://github.com/dlang/dub). We can use it to create our project and build the xll.

    $ dub init exceld
    Package recipe format (sdl/json) [json]: sdl
    Name [exceld]:
    Description [A minimal D application.]:
    Author name []:
    License [proprietary]:
    Copyright string [Copyright ┬® 2020, ]:
    Add dependency (leave empty to skip) []: excel-d
    Adding dependency excel-d ~>0.5.8
    Add dependency (leave empty to skip) []:
    Successfully created an empty project in 'exceld'.
    Package successfully created in exceld

Next delete source/app.d and create main.d and funcs.d in the source folder.

main.d
```d
import xlld;
mixin(wrapAll!(__MODULE__, "funcs"));
```

funcs.d
```d
import xlld;

@Register(ArgumentText("Array to add"),
		HelpTopic("Adds all cells in an array"),
		FunctionHelp("Adds all cells in an array"),
		ArgumentHelp(["The array to add"]))
double FuncAddEverything(double[][] args) nothrow @nogc {
	import std.algorithm: fold;
	import std.math: isNaN;

	double ret = 0;
	foreach(row; args)
		ret += row.fold!((a, b) => b.isNaN ? 0.0 : a + b)(0.0);
	return ret;
}
```
Edit the build file, dub.sdl, to contain the following:

```d
name "exceld"
description "A minimal D application."
authors ""
copyright "Copyright © 2020, "
license "proprietary"
dependency "excel-d" version="~>0.5.7"
targetType "dynamicLibrary"
dflags "-dip25" "-dip1000"

configuration "xll" {
    preBuildCommands "dub run -c def --nodeps -q -- exceld.def"
    sourceFiles "exceld.def"
    # must have the appropriate 32/64 bit Excel SDK xlcall32.lib in the path of the app
    # unfortunately they're both called xlcall32.lib

    libs "xlcall32"
    postBuildCommands "copy /y exceld.dll exceld.xll"
}

configuration "justxll" {
    sourceFiles "exceld.def"
    # must have the appropriate 32/64 bit Excel SDK xlcall32.lib in the path of the app
    # unfortunately they're both called xlcall32.lib

    libs "xlcall32"
    postBuildCommands "copy /y exceld.dll exceld.xll"
}


// This builds a binary that writes out the necessary .def file
// to export the functions
configuration "def" {
    targetType "executable"
    targetName "write_def"
    versions "exceldDef"
}
```

Finally, copy the desired XLCALL32.LIB file from your Excel SDK install (can be downloaded from [Microsoft](https://www.microsoft.com/en-us/download/details.aspx?id=35567)) and run the build command:

	$ dub build --arch=x86_mscoff # For 32 bit
	$ dub build --arch=x86_64 # For 64 bit

This should create an "exceld.xll" file in the top level directory. If we open the add-in in excel (explorer.exe exceld.xll can be used on the command line) we can use the function in a spreadsheet.

![Excel screenshot](/images/excel_d_udf.png)

# Conclusion

Considering I had never written any D before I was able to get a simple UDF up and running without too much trouble. Excel-d appears to be a very good option if you wish to create custom UDFs, however at the moment it has no support for UI extensions. Also, beginner level documentation is lacking so the best way to find out more is by reading the code in the [excel-d repo][3].

[1]: https://dlang.org/
[2]: https://blog.jonharrington.org/calling-rust-from-excel/
[3]: https://github.com/symmetryinvestments/excel-d