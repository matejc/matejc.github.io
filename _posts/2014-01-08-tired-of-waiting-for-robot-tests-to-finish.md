---
layout: post
title: Tired of waiting for Robot tests to finish?
tags:
- cli
- linux
comments: true
---

Running Robot (Selenium) tests makes computer unusable for user.


Robot tests are functional tests and are made to run a web browser and test your application by triggering actions on page usually running on localhost, all that, right on your screen, therefore for the time being, user can't use the computer. But there is a solution, you could use VNC to fool Robot tests to run on some other screen instead.

This is an example of using TightVNC server:

{% highlight bash %}
# this command runs the VNC server on screen :99
vncserver :99

# start your tests by setting DISPLAY env variable
DISPLAY=:99.0 bin/robot --layer PyramidRobotLayer

# and then kill the VNC server
vncserver -kill :99
{% endhighlight %}

You can use any other VNC server, or even Xvfb if you like.
