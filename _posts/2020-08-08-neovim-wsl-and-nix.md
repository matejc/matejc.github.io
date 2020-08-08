---
layout: post
title: Neovim, WSL and Nix
tags:
- wsl
- neovim
- nixos
comments: true
---


How to use Neovim (Neovim-Qt) under WSL 1/2 with the power of Nix


## Intro

Well we all know that generally development on Linux is easier than on Windows, but sometimes you are forced to use Windows. But that does not mean that all those nice tools from Linux are not available to you, as we will see in this post.

Windows has some thing called WSL which enables you to run Linux tools natively in the Windows subsystem.
Not all is without issues, you can not run graphical Linux applications because Windows does not run Xorg server, yeah you have Xorg ports that run there but that is in this case just one more unwanted layer, remember, building efficient solutions is what every engineer should strive to.

What I did is to use Windows pre-built binaries of Neovim-Qt and run the Neovim installed with Nix inside WSL.

Ok, you could say then, why not use VS Code with some Vim/Neovim plugin and use so called Remote-WSL plugin to access WSL... Well yes, but at least me I stumble upon few issues.
First was that CPU usage was through the roof when Remote-WSL extension was in use on WSL1 (I could not just run Windows Update on client's managed computer) and the fix was to install specific version of libc with dpkg (which is absurd in the first place because this is a good way to ruin your whole environment).
Applying this fix did the trick for lowering the CPU usage. The second issue come right after, when I wanted to install some package with APT package manager, like I predicted, libc install did its damage, I could not install or un-install anything with APT. Nix comes again to the rescue.

By the way the **sleep** command forgot how to work under WSL and Ubuntu 20.04 [Source](https://askubuntu.com/questions/1230252/sleep-doesnt-work-on-ubuntu-20-04-wsl).

## Let's see the solution

### Neovim-Qt

Neovim-Qt has nicely built binaries on their GitHub page for Windows, so I just downloaded that zip and unpacked it into **C:/Program Files/neovim-qt/**. But any location could do.


### WSL

Open PowerShell as Administrator and run:

{% highlight powershell %}
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
{% endhighlight %}

If you do not have up to date Windows for any kind of reason to install WLS2 then reboot now.

**Reboot Time**

You should have now enabled the WSL1 and you can proceed to install Ubuntu 20.04 (or any other Linux distro you like) from Microsoft store.
Do not forget to click Launch after installing it (it will ask you to create a user).


### Nix

To install Nix, you need to first open some terminal emulator and run **wsl.exe**, but you can also just run it from Start menu.

{% highlight bash %}
bash <(curl -L https://nixos.org/nix/install)
{% endhighlight %}

To finish you can just close the terminal and open wsl.exe again.

Thats it.


### The Nix script

Now here is the absolutely most awesome part that connects everything together.

{% highlight nix %}
{ pkgs ? import <nixpkgs> {} }:
pkgs.writeScript "run-neovim-qt.sh" ''
    #!${pkgs.stdenv.shell}
    set -e

    # get random free port
    export NVIM_LISTEN="127.0.0.1:$(${pkgs.python3Packages.python}/bin/python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')"

    # use python's sleep, because coreutils' sleep does not function under Ubuntu 20.04 and WSL
    #   after delay start nvim-qt - so that nvim starts before the GUI
    { ${pkgs.python3Packages.python}/bin/python -c 'import time; time.sleep(1)'; "''${NVIM_QT_PATH}" --server "$NVIM_LISTEN"; } &

    # start nvim
    ${pkgs.neovim}/bin/nvim --listen "$NVIM_LISTEN" --headless "$@"
''
{% endhighlight %}

Save it to your drive or download with **wget** under WSL:

{% highlight bash %}
wget https://raw.githubusercontent.com/matejc/helper_scripts/master/nixes/neovim-qt.nix 
{% endhighlight %}

Then build the command with:

{% highlight bash %}
nix-build ./neovim-qt.nix
{% endhighlight %}

The resulting script is **./result**.


### Usage

First we need to tell the script where is the Neovim-qt located:

{% highlight bash %}
export NVIM_QT_PATH='/mnt/c/Program Files/neovim-qt/bin/nvim-qt.exe'
{% endhighlight %}

You can save this into **.bashrc** or **.profile** and restart the terminal so that you do not need to repeat the step every time you run wsl shell.

The final step is:

{% highlight bash %}
./result my/awesome/code.py
{% endhighlight %}


## Conclusion

Too much work? You think? Well how much more time you would use using and configuring VS Code or Atom to work under similar environment?
And what about Nix? You can install it without the use of native package managers (in case the native one is b0rked) and once you do, you have the power to install your favorite development environment with single command.

I like this solution, in my eyes its simple and efficient, what are your thoughts?

Until next time... I wish you happy hacking!

## Links

[High cpu usage of node process in Remote-WSL extension #2921](https://github.com/microsoft/vscode-remote-release/issues/2921)
[Neovim-Qt Releases](https://github.com/equalsraf/neovim-qt/releases)
[WSL on Windows 10](https://docs.microsoft.com/en-us/windows/wsl/install-win10)
[Quick start with Nix](https://nixos.org/nix/manual/#chap-quick-start)
