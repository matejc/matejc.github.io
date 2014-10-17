---
layout: post
title: Control your packages with Nix created profiles!
tags:
- nixos
- cli
- linux
---

Nix has many advantages over most of the other package managers, today, I am going to write about one of them.


Nix is a package manager for the NixOS, but you can install it to other operating systems. One problem on so-called normal systems is that you are/should be very jumpy when installing packages, because you just do not know what and specially where it is going to be installed. Try removing that then...

Well there is a solution - Nix - which works like this: when you install the package, it goes directly to some long-named folder with hash in its name to /nix/store/... and linked into the profile which is available to specific user or all of the users, you can create environments with those profiles.

There are three ways to install a package with Nix

1. Into the **system environment** inside global system */etc/nixos/configuration.nix* (available only for NixOS users),
2. into the **user environment** with command *nix-env --install <package_name>* and
3. into the **custom environment**


#### System environment

Example (declare inside */etc/nixos/configuration.nix*):

{% highlight nix %}
environment.systemPackages = [ pkgs.perl pkgs.emacs pkgs.thunderbird pkgs.firefox ];
{% endhighlight %}

Not much to say, packages will be downloaded from cache or compiled if binaries are not available.

Remember: when installing i.e. some perl application, in one environment, you will not see perl executable itself, you will have to specify it separately.


#### User environment

Example (as normal user, without sudo of course):

{% highlight bash %}
$ nix-env -iA pkgs.emacs24
{% endhighlight %}

This package will be installed to something like */nix/store/qv39sv3981kk5h4p260y879wilfc3c26-emacs-24.3* let's see what is inside (two levels deep)

{% highlight bash %}
/nix/store/qv39sv3981kk5h4p260y879wilfc3c26-emacs-24.3
|-- bin/
|   |-- ctags*
|   |-- ebrowse*
|   |-- emacs -> emacs-24.3*
|   |-- emacs-24.3*
|   |-- emacsclient*
|   |-- etags*
|   `-- grep-changelog*
|-- libexec/
|   `-- emacs/
|-- share/
|   |-- applications/
|   |-- emacs/
|   |-- icons/
|   |-- info/
|   `-- man/
`-- var/
    `-- games/
{% endhighlight %}

You can see that everything from this package is in one place. Dependencies are also taken care of in similar manner and are reused for other packages of course.

Well how the hell do users see/use right package? The answer is simple: each user has its own profile which is a folder and links are created into it.

If some other user wants emacs23 and not emacs24, that is not the problem, dependencies are going to be reused and new links into other user profile will be created.


#### Custom environment

Now here the fun starts!

If you want emacs23 side by side with emacs24, you need to create a custom environment. In this example I will create two custom environments, one for each package, but you can have one emacs in user env. and one in custom env.

Edit/create a new file *~/.nixpkgs/config.nix*:

{% highlight nix %}
{
  packageOverrides = pkgs:
  rec {
    homeEnv = pkgs.buildEnv {
      name = "homeEnv";
      paths = [ pkgs.emacs24 pkgs.bsdgames ];
    };
    workEnv = pkgs.buildEnv {
      name = "workEnv";
      paths = [ pkgs.emacs23 pkgs.perl ];
    };
  };
}
{% endhighlight %}

Then you need to build those two profiles:

{% highlight bash %}
$ nix-env -p /nix/var/nix/profiles/per-user/<YOUR_USERNAME>/workEnv -i workEnv
{% endhighlight %}

{% highlight bash %}
$ nix-env -p /nix/var/nix/profiles/per-user/<YOUR_USERNAME>/homeEnv -i homeEnv
{% endhighlight %}

I choose to create profiles inside */nix/var/nix/profiles/per-user/YOUR_USERNAME/* folder, but you can use *~/.profiles/* or something. The *-i* flag is the *--install* flag that we seen before and we are this time installing profiles named homeEnv and workEnv. Let us see what is inside homeEnv (this time one level deep):

{% highlight bash %}
/nix/store/rg4zh4s2gaw1b3dm2kgicis8admsaanx-homeEnv
|-- bin/
|-- libexec -> /nix/store/qv39sv3981kk5h4p260y879wilfc3c26-emacs-24.3/libexec/
|-- share/
`-- var -> /nix/store/qv39sv3981kk5h4p260y879wilfc3c26-emacs-24.3/var/
{% endhighlight %}

You can see that profile is actually created inside */nix/store* and if some other user chooses to create the same packages for his profile, only one link will be created - his profile will be the same as yours.

One thing remains... create two more files, one for home environment

{% highlight bash %}
export PATH=/nix/var/nix/profiles/per-user/<YOUR_USERNAME>/homeEnv/bin
$@
{% endhighlight %}

and one for work environment

{% highlight bash %}
export PATH=/nix/var/nix/profiles/per-user/<YOUR_USERNAME>/workEnv/bin
$@
{% endhighlight %}

you will need to source those files to set environment variables for the profile or make them executable (also make them available in PATH env variable) and run commands as CLI arguments (hence the *$@*)

This was child's play, environments are more useful in development, you can have one environment for Perl development and the other one for Python, of course in every profile, applications will see only each other, well that depends also on shell environment variables, for my Python 2.7 profile, this file now looks like this

{% highlight bash %}
#!/usr/bin/env bash

NIX_USER_PROFILE_DIR=/nix/var/nix/profiles/per-user/matej
nixprofile=$NIX_USER_PROFILE_DIR/py27

export PATH="$nixprofile/bin"
export LD_LIBRARY_PATH="$nixprofile/lib"
export NIX_LDFLAGS="-L$nixprofile/lib -L$nixprofile/lib/pkgconfig"
export NIX_CFLAGS_COMPILE="-I$nixprofile/include -I$nixprofile/include/sasl"
export PKG_CONFIG_PATH="$nixprofile/lib/pkgconfig"
export PYTHONPATH="$nixprofile/lib/python2.7/site-packages"
export PS1="py27 $PS1"

export INCLUDE="$nixprofile/include:$INCLUDE"
export LIB="$nixprofile/lib:$LIB"
export C_INCLUDE_PATH="$nixprofile/include:$C_INCLUDE_PATH"
export LD_RUN_PATH="$nixprofile/lib:$LD_RUN_PATH"
export LIBRARY_PATH="$nixprofile/lib:$LIBRARY_PATH"
export CFLAGS=$NIX_CFLAGS_COMPILE
export LDFLAGS=$NIX_LDFLAGS

"$@"
{% endhighlight %}

This concludes this post and do please leave a comment bellow.
