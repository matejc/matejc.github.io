---
layout: post
title: Restart process on file change
tags:
- cli
- linux
comments: true
---

Someone on irc (on channel #kiberpipa at freenode) was trying to solve a bash problem so I decided to challenge myself ... here it goes ...

#### Problem

- language: bash
- with only basic Linux cli tools
- run some blocking (non-daemon) command, and restart it when some *.coffee file changes on file system
- that command must output to stdout and stderr to foreground


#### Solution

{% highlight bash %}
#!/usr/bin/env bash

MYCOMMAND='while [ true ]; do sleep 1; echo "beje"; done'

# This will take down the whole process tree on script exit
trap "exit" INT TERM
trap "kill 0" EXIT

while true; do
    sleep 1;
    NEW_OUTPUT=`find . -name \*.coffee -exec openssl sha1 {} \;`;

    if [ "$NEW_OUTPUT" != "$OLD_OUTPUT" ]
    then
        # output changed
        if [ "$MYPID" ]; then kill -9 $MYPID; fi
        bash -c "$MYCOMMAND" &  # command will output to stdout
        MYPID=$!;
        OLD_OUTPUT="$NEW_OUTPUT";
    fi

done
{% endhighlight %}

Variable MYCOMMAND is of course adjustable to what-ever command you would like to use. Right now it represents the command that is output-ing to stdout word "beje" (semi-random word from my brain) that runs in foreground. Then script enters everlasting while loop that sleeps 1 second, each iteration. Then it saves the output of command combination, find and openssl, which basically means .. sha1 hash of every file in current directory tree. Then on FIRST iteration and on every CHANGE, script tries to kill the previously ran MYCOMMAND if any, after that it executes that command - which means that right now the MYCOMMAND was restarted, after saving few variables for future iteration, loop repeats the process.

Trap is necessary that whathever this script started, stops when user uses ctrl+c key combination. Thanks to this [thread](http://stackoverflow.com/questions/360201/kill-background-process-when-shell-script-exit).
