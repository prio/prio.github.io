---
​---
layout: post
title: Please fix your dependencies
image: /images/scream.jpeg
​---
---

# Please use fixed versions for your (application) dependencies

When I was in university we were taught all about software components. "Object orientation has failed us when it comes to re-use" we were told, "they were too fine grained, components are the solution".

Lecturers told us of the component marketplaces we would use, and how we would use UIs to draw lines between components to build our software. A nice idea, obviously hasn't happened.

It turns out re-use wasn't a technology or a "grain" problem, it was a licence and cultural problem. The internet and free/open source software have solved it. Nowadays when starting a new project in any language the first thing we do is create a build/configuration file that lists our dependencies and downloads them for us. It's fantastic, except....



# That is all

We now have dependency hell, thats a story for another day, however if you are developing an end user application, a web app, an electron app, a desktop UI app, that will not be included in someone else codebase as a library, please **FIX YOU DEPENDENCIES AT KNOWN WORKING VERSION**. If you are working on a proprietary piece of code that will not be shared outside your organisation **FIX YOU DEPENDENCIES AT KNOWN WORKING VERSION**. Time and time again I check out an application, build/run it and I have to go and downgrade or patch packages your application depends on. Your application breaks through no fault of your code.

Open source is brilliant, the culture of sharing and collaborating on code using services such as github is brilliant, I am not asking for support, but please, fix your dependencies at a known working version and make it easier for end users to use and enjoy (and maybe contribute to) your hard work. That is all.

