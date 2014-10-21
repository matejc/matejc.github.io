---
layout: post
title: Black to blue
tags:
- cli
comments: true
---

Convert black to blue using ImageMagick.


Have you ever desperately needed to print a pdf or image file but your printer ran out of black color and still have blue? With this command you can resolve this issue by replacing black color with blue:

{% highlight bash %}
convert -density 300x300 in.pdf -fuzz 40% -fill "#0000FF" -opaque "#000000" out.pdf
{% endhighlight %}
