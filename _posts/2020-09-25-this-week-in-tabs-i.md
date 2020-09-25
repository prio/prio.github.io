---
layout: post
title: This week in tabs
cover: images/pexels-kei-scampa-3009487.jpg
navigation: True
class: post-template
subclass: 'post'
---

Some interesting data, maths and programming related content I stumbled across recently.

![NumPy logo](https://upload.wikimedia.org/wikipedia/commons/thumb/3/31/NumPy_logo_2020.svg/220px-NumPy_logo_2020.svg.png)

The NumPy paper! Charles R. Harris et. al. publish a paper about [NumPy](https://numpy.org/) in Nature. NumPy is the foundation of pretty much every Python data related library and tool so cite liberally [link](https://www.nature.com/articles/s41586-020-2649-2).

Barry Render highlights some of the difficulties suppliers are currently having with PPE inventory [Article](https://heizerrenderom.wordpress.com/2020/09/24/om-in-the-news-supply-chains-struggle-to-maintain-ppe-inventory/)

Laura Labert discussed a paper she and a student recently published which describes a discrete event simulation approach to planning an election during the current COVID-19 pandemic. Recommendations include more staff and a sperate queue for those deemed high-risk. [link](https://punkrockor.com/2020/09/23/resilient-voting-systems-during-the-covid-19-pandemic-a-discrete-event-simulation-approach/).

# Python 3.9

Python 3.9 beta is out [link](https://www.python.org/downloads/release/python-390b3/). A few of the new features it will bring:

**[PEP 584: Add Union Operators To dict](https://www.python.org/dev/peps/pep-0584)**
The | union and update |= operators are now available for dictionaries. 

```Python
# Union
d3 = d1 | d2

# Update
d1.update(2)
# becomes
d1 |= d2
```
**[PEP 585: Type Hinting Generics In Standard Collections](https://www.python.org/dev/peps/pep-0585/)**

Standard collection types are now generic allowing them to be used in type hints. This has been possible since 3.7 by importing annotations from future but this update ensures external tools such as Mypy will behave as expected.

```Python
from __future__ import annotations

def find(haystack: dict[str, list[int]]) -> int:
	return 0
```

**[PEP 593: Flexible function and variable annotations](https://www.python.org/dev/peps/pep-0593/)**

Annotated type is added to the typing module to allow metadata to be applied to existing types. The example below shows two ints annotated with `c` information.

```Python
UnsignedShort = Annotated[int, struct2.ctype('H')]
SignedChar = Annotated[int, struct2.ctype('b')]
```

**[PEP 616: String methods to remove prefixes and suffixes](https://www.python.org/dev/peps/pep-0616/)**

Two new string methods added:

```Python
> "python".removeprefix("py") # "thon"
> "python".removesuffix("on") # "pyth"
```

**[PEP 617: New PEG parser for CPython](https://www.python.org/dev/peps/pep-0617/)**

A behind the scenes change, but I am very interested in parsing techniques so its nice to see Python get this update. 

(Side note: this reminded me of the great work Alessandro Warth did on [OMeta](http://tinlizzie.org/ometa/) a few years ago as part of his PhD. It turns out, for me, "a few years ago" now equals 13 :grimacing: )

# "The algorithm"

<img src="https://media.wired.com/photos/5f61109fd2d0ba5ef0f2302f/master/w_2560%2Cc_limit/ff_youtube_top_.jpg" alt="Wired Cover" style="zoom: 25%;" />

> "Sargent's videos are intentionally lo-fi affairs. There's often a slide show that might include images of Copernicus (deluded), astronauts in space (faked), or Antarctica (made off-limits by a cabal of governments to hide Earth's edge), which appear onscreen as he speaks in a chill, avuncular voice-over .... Crucial to his success, he says, was YouTube's recommendation system" - [Wired](https://www.wired.com/story/youtube-algorithm-silence-conspiracy-theories/)

A recent episode of the Not So Standard Deviations discussed how "the algorithm" was the reason for TikToks valuation [link](https://nssdeviations.com/114-we-need-tiktok-help).

When discussed in the context of YouTube it is often blamed for the rise of bizarre conspiracy theories such as a belief in flat earth theories, QAnon and the rise of the far right. A recent episode of the real story by the BBC world service went into more detail on the QAnon conspiracy [link](https://www.bbc.co.uk/programmes/w3cszcnc). The rabbit hole podcast from the New York times was recommended as a more in-depth review of the subject [link](https://www.nytimes.com/2020/04/16/technology/rabbit-hole-podcast-kevin-roose.html) .

And finally, Wired discusses the issues YouTube have had using AI to moderate content [link](https://www.wired.com/story/youtube-algorithm-silence-conspiracy-theories/) [[via]](http://marketdesigner.blogspot.com/2020/09/filtering-inappropriate-content-is.html).

# Conferences/Videos/Streams

* The ICML (International Conference on Machine Learning)  talks are now online [link](https://slideslive.com/icml-2020).
* CPPcon finished recently and its videos are also appearing on its YouTube channel [link](https://www.youtube.com/user/CppCon)
* Markus Loning shows off [sktime](https://github.com/alan-turing-institute/sktime), a machine learning library for time series, at PyData Fest Amsterdam [link](https://www.youtube.com/watch?v=Wf2naBHRo8Q&t=424s)
* All the videos from this years excellent JuliaConf are now also online [link](https://www.youtube.com/playlist?list=PLP8iPy9hna6Tl2UHTrm4jnIYrLkIcAROR).