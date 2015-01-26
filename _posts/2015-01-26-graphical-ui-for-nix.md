---
layout: post
title: Graphical UI for Nix/NixOS
tags:
- nixos
- nix
comments: true
---

I started this project as a web UI for Nix, but after my first blog post I had a lot of questions from you, what about the desktop application? So here it is.


### What is new?

 - rewritten app from web UI to desktop UI
 - still JavaScript, more accurately NodeWebkit
 - beside package manager there is now configuration browser
 - no more services, like web server and ElasticSearch
 - and still using Polymer


### Preview of 0.1.1 version

#### Front Page - Package Manager

![Front Page - Package Manager](/img/post/nixui/FrontPage-PackageManager.jpg){: class="post-img"}


#### Front Page - Configuration Options

![Front Page - Configuration Options](/img/post/nixui/FrontPage-ConfigurationOptions.jpg){: class="post-img"}


#### Package Browser

![PackageBrowser](/img/post/nixui/PackageBrowser.jpg){: class="post-img"}


#### Package Info

![Package Info](/img/post/nixui/PackageInfo.jpg){: class="post-img"}


#### Manage Marked

![Manage Marked](/img/post/nixui/ManageMarked.jpg){: class="post-img"}


#### Configuration Browser

![Configuration Browser](/img/post/nixui/ConfigurationBrowser.jpg){: class="post-img"}


### How to try it out?

There are two ways, the development version and from the nixpkgs. Both described below.


#### Development

To get the code you will need git:

{% highlight bash %}
$ git clone https://github.com/matejc/nixui
$ cd nixui
{% endhighlight %}

If you do NOT use `nix-channel` to update, then modify config file `./src/config.json` so that `NIX_PATH` entry has `nixpkgs=/path/to/your/nixpkgs`.

Mine looks like this:

{% highlight json %}
{
    "profilePaths": ["/nix/var/nix/profiles"],
    "dataDir": "/tmp",
    "configurations": ["/etc/nixos/configuration.nix"],
    "NIX_PATH": "nixpkgs=/home/matej/workarea/nixpkgs:nixos=/home/matej/workarea/nixpkgs/nixos:nixos-config=/etc/nixos/configuration.nix:services=/etc/nixos/services"
}
{% endhighlight %}

Then build and run NixUI with following command, you will need `gnumake` and `nix` for this:

{% highlight bash %}
$ make just-run-it
{% endhighlight %}


#### Nixpkgs

Again, if you do NOT use `nix-channel` to update, then make sure that `config.nixui.NIX_PATH` entry has `nixpkgs=/path/to/your/nixpkgs`.
In your main configuration nix file add the line `nixpkgs.config.nixui.NIX_PATH="nixpkgs=/path/to/your/nixpkgs";`, OR in user config add this line to `~/.nixpkgs/config.nix`: `nixui.NIX_PATH="nixpkgs=/path/to/your/nixpkgs";`.

Install it like any other package, like so:

{% highlight bash %}
$ nix-env -iA pkgs.nixui
{% endhighlight %}

Warning: at the time of writing this blog post, the `nixui` package was NOT yet in unstable channel, but was merged into master, therefore it is only a matter of time when it will be available.


### Plans for the future

In the near future, bug fixes and after NixUI gets stable enough and I get some money from other projects, I will start on Nix configuration editing.
