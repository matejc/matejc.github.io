---
layout: post
title: Git work log
tags:
- cli
- git
comments: true
---

My git work log command.


Copy those two lines to new file named 'gitworklog', then save it in some .../bin/ folder (i.e. /usr/bin/) and make it executable.

{% highlight bash %}
#!/bin/bash

find $(pwd) -type d -name ".git" -exec sh -c "cd \"{}/..\" ; echo -e \"\n{}\" ; git --no-pager log --since='$1' --branches --remotes --tags --pretty=format:' %Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(green)<%an>%Creset' --committer='$2'" \;
{% endhighlight %}

Usage:

{% highlight bash %}
gitworklog <since> <commiter>
{% endhighlight %}

Examples:

{% highlight bash %}
$ gitworklog '2 days ago' 'Your Name'

$ gitworklog 'yesterday' 'Your Name'

$ gitworklog 'last friday' 'Your Name'
{% endhighlight  %}
