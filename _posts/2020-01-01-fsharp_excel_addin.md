---
layout: post
title: F# Excel Add-In
image: /images/chart-close-up-data-desk.jpg
---

This is a post is based on information found in various repos and wiki pages on Github but I felt it was worth putting it all together along with some screenshots of Visual Studio 2019 for someone starting out in the .NET ecosystem.

# Introduction

I am going to assume you know what F# is and why you would want to use it. I am also going to assume you are familiar with Excel. In this post we will build a simple Excel plug-in that:

* Exposes functions for use within a worksheet
* Contains the bulk of its Logic in a .NET Standard library
* Uses Excel-DNA and .NET Framework (by necessity) to generate the add-in

Separating our solution into two or more projects allows us to write more portable and future proof code for our business logic, while still using Excel-DNA which depends on the windows only .NET framework.



## .NET what?

![.NET Platforms](/images/excel_fsharp/dotnet_platforms.png)



If you are new to the .NET ecosystem and from a JVM background or similar the different versions of .NET can at first seem confusing. 

The .NET framework is the original (and now legacy) Microsoft implementation. It is widely used, has the largest library support and contains the largest number of APIs. However it is not the future of the platform, that mantle has been passed to .NET Core. 

The .NET Core implementation is the newer, open source, cross platform implementation from Microsoft. It is less mature than .NET Framework but catching up quickly. Where ever possible new code should target .NET Core. 

Xamarin (aka mono) is another open source and cross-platform implementation originally written by a third party company. Microsoft purchased Xamarin in 2016 and Xamarins main focus is now on a runtime and solution for mobile iOS and Android developers. 

Finally, .NET Standard (aka BCL) is a description of the APIs and components provided by all of the aforementioned implementations. If your code targets .NET Standard it can be used in .NET framework, .NET Core and Xamarin apps.



# Create and setup the solution

![Create a new project](/images/excel_fsharp/1_new_project.png)

The first thing we need to do is create a new F# .NET Framework project.



![Ensure F# desktop support is installed](/images/excel_fsharp/2_fsharp_desktop_support.png)

**Note** it must be a .NET Framework project. If this template is not available you will need to check the visual studio installer and make sure you installed desktop support for F#.



![Configure](/images/excel_fsharp/3_configure.png)

I named the project "MyAddIn". Next we can remove the files we don't require. Delete the automatically generated "AssemblyInfo.fs" and "Script.fsx" files.



![Nuget Package Manager](/images/excel_fsharp/4_open_nuget.png)

Next, add the Excel-DNA library using the Nuget package manager.



![Add Excel-DNA](/images/excel_fsharp/5_install_excel_dna.png)

Click on "Browse" and search for Excel-DNA. Install the "ExcelDna.AddIn".



## Set up Excel

Next, we will make a small change to our Excel settings to make it easier to see any errors.

![Setup Excel](/images/excel_fsharp/6_setup_excel.png)

Open Excel, in the file tab open Options. Select the advanced category and under "General" tick the "Show add-in user interface errors" checkbox. Save your settings and exit Excel.



## Modify the "Entry Point" project

Now we will set up the project to allow for easier user testing and debugging.



![Debug Settings](/images/excel_fsharp/7_debug_settings.png)

Open the projects properties screen and select the debugging tab. In the "Start external program" text field put the full path to your Excel application. For "Command line arguments" but the path to the add-in you want to test. Excel-DNA generates a number of Add-Ins. I don't want to go to much into the details of Excel-DAN in this post but for easy distribution you can use the "-packed" add-ins. Both 32 and 64 bit versions of the xll are created.



Change the code in Library1.fs to the following:

```F#
module MyAddIn

open ExcelDna.Integration

[<ExcelFunction(Description="My first .NET function")>]
let HelloDna name =
    "Hello " + name
```

We can now test it.

![Test it out](/images/excel_fsharp/8_simple_test.png)

If you now hit start (or press F5) Excel should open. Enable the add-in for this session only and test it out.



## Create the business logic project

The "logic" project will target .NET Standard. This gives us more options in the future if we want to re-use the same logic in a Xamarin mobile application or a .NET Core web application.

![New Project](/images/excel_fsharp/9_new_project.png)

Right Click on your solution and Add a new project. This time we will use the "Class Library (.NET Standard)" template and call it "Logic". Change the code in "library.fs" to:

```
namespace Logic

module Say =
    let hello name =
        "Hello " + name
```



We now need to call our new "portable" code. 



![Add reference](/images/excel_fsharp/10_add_link.png)

Back in our entry point project (MyAddIn) add the new project "Logic" as a reference and change the code in "Library1.fs" to use the function from our .NET Standard library instead:

```
module MyAddIn

open ExcelDna.Integration
open Logic.Say

[<ExcelFunction(Description="My first .NET function")>]
let HelloDna name = hello name
```



## Create the test project

Finally, we will create a test project to test our business logic code.



![Add xUnit Project](/images/excel_fsharp/11_unit_project.png)

This time we choose the xUnit Test Project (.NET Core) and call it "Logic.Test". 

Again, we add "Logic" as a reference to it and we change the test code in "Tests.fs" to:

```F#
module Tests

open System
open Xunit
open Logic.Say

[<Fact>]
let ``My test`` () =
    Assert.Equal("Hello jon", hello("jon"))
```

![Tests Pass](/images/excel_fsharp/12_tests_passing.png)

Right click on the project select "Run Tests". The Test explorer will appear and show the test passing.



# Conclusion

In this post we have seen how to create a simple Excel add-in using F#. We have also learned how to split out our code into a more portable library to allow for future re-use in other projects.

 Although this post uses Visual Studio 2019 on Windows (as Excel-DNA is windows only) the quality of the tooling being built by Microsoft .NET Core is also very impressive and well worth a look. I am excited to delve deeper into the ecosystem and start using F# in data projects.
