---
layout: post
title: Nix's very own graphical UI
tags:
- nixos
- linux
comments: true
---

I have been working on this project for the last two months and now it is time for some feedback


I have been using NixOS operating system for about two years now, and it is time that I do something more than to package packages and play with Hydra.

At the last year's NixOS sprint called Zidanca sprint here in Slovenia I had a little joke about making front-end for Nix package manager in JavaScript, well, now it is not a joke any more.

Why JavaScript?

This language had become quite popular lately so I decided to take a look at it, and I like a new challenge.

Technologies used:

- NodeJS for backend (expressjs)
- Nix package manager commands (nix-env and nix-instantiate)
- Web Components for frontend (Polymer)
- ElasticSearch for search and package cache

#### Well, let's start...

There is no npm/nix package made yet, but I am planing to do it when the project reaches right maturity, should be soon.

Requirements:

- git
- make
- Nix package manager
- Browser

Code is at GitHub so let's get it and enter the folder

{% highlight bash %}
$ git clone https://github.com/matejc/nixui
$ cd nixui
{% endhighlight %}

To build the environment (get node, bower and elasticsearch packages) and place links to the right places inside the folder, do not worry this is not going to touch your system

{% highlight bash %}
$ make build
{% endhighlight %}

This command fires up Nix package manager and installs all the packages in custom environment (make is here just so that you do not have to write a bunch of commands and make appropriate links)

This is going to take a few minutes and when it is done, you should have bin folder (well, a link to it), next, you will have to run ElasticSearch:

{% highlight bash %}
$ ./bin/services-nixui-start-services
{% endhighlight %}

you can check if it went well with this:

{% highlight bash %}
$ cat ./var/log/elasticsearch-*.log
{% endhighlight %}

There is only one more step, run the server

{% highlight bash %}
$ make develop
{% endhighlight %}

If everything went well, you will see the message (wait a few seconds to appear, it has to index all the packages): `NixUI at http://localhost:8000/index.html`

Success! Open the browser at `http://localhost:8000/index.html`

and you should see something like this

![first look](/img/post/e0352d7c-e666-4bb3-80b0-ce6aa8e41a09.png){: class="post-img"}

This process was tested on NixOS and should work on any Linux distribution with Nix package manager installed.

#### Usage

Searching with wildcard

![wildcard search](/img/post/f9cbb31f-7808-4ee8-8c1f-1cb45c062bf4.png){: class="post-img"}

Search for installed packages with `!i`

![search install](/img/post/76361524-7a09-48a2-a9a6-5f3570792032.png){: class="post-img"}

Web UI has simple authentication for security reasons - if you have server running while some other user is running different session - we do not want that others install packages in your environment.

Click on the package and enter development/testing credentials: user: bob, password: secret

![simple auth](/img/post/59d9dfb5-1680-421d-8aa6-ce41f12fc312.png){: class="post-img"}

On package information window you can mark package for install, click on `AVAILABLE!` button or for removal from marked list, click on `MARKED AS INSTALLED!`, for unistallation the process is similar (button will appear when you enter credentials).

#### Manage marked dialog

From the menu (top right) select `Manage Marked ...`

![manage marked](/img/post/9df1140d-4158-48eb-b06e-3bccbfcd719c.png){: class="post-img"}

Here you can apply (install/uninstall) or remove marked packages.


#### Plans for the future

I will be at the [NixOS sprint](http://www.kiberpipa.org/nixos-sprint-ljubljana-2014/), well not only that, I am helping to organize it. At the sprint I will be working on your wishes to make this project better.

Managing packages in your user environment is scratching the surface of what you can do with Nix, so I have an idea to visualize and later even edit your main NixOS configuration.nix file as a tree or some other cool structure. Traces of this idea are already in project's GitHub repository as Nix scripts (*src/config_all.nix* and *src/config_inuse.nix*).

Comments and help are much obliged!

And I am available for hire!

This concludes our transmission, I hope you liked it, but stay tuned, project is under development!
