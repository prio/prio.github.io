---
layout: post
title: Please fix your dependencies
image: /images/scream.jpeg
---

Please use fixed versions for your application dependencies.

While at university our lecturers spoke at length about software components. "Object orientation has failed us when it comes to re-use" we were told, "objects are too fine grained, too specific, components are the solution".

We were told to imagine the component marketplaces we would peruse, and how we would use point and click tools to draw lines between components to build our software. A nice idea, it's happened, just not in the way we were told it would.

It turns out re-use wasn't really a technology or a "grain" problem, it was a license and cultural problem. The Internet and free/open source software have solved it in ways we couldn't imagine all those years ago (It was only 15 years ago). Nowadays when starting a new project in any language the first thing we do is create a build/configuration file that lists our dependencies and run a tool that will automatically download and mange them for us. It's fantastic, except when it's not.

If you are developing an end user application, be it a a web app or a desktop app, use fixed versions for your dependencies. By default many build tools won't add a dependency version, or will had a prefix allowing any minor version assuming it will work fine, often it won't.

Time and time again I check out an application, and go to run it only to find I have to go and downgrade or patch packages your application depends on. Your application breaks through no fault of your code. 

Open source is fantastic, this culture we have of sharing and collaborating, of offering our work to others for free so they can get on with solving the problem at hand is something I am very grateful for. However, it doesn't need to be this hard. Please fix your dependencies to known working versions and make it easier for end users to use, enjoy and maybe even contribute to your hard work. We will all benefit.
