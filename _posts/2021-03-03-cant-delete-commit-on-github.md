---
layout: post
title: Can't delete commit on GitHub
tags:
- github
- git
- bug
comments: true
---


You can permanently delete commits on GitHub, right? Well... no.


## Intro

After you send a commit to GitHub, it can not be deleted by force pushing changed history
those commits stay on site until you delete the repository itself
(or maybe by some manual cleaning action from GitHub itself).
Meaning that your secret changes you have accidentally pushed, are still up there and that is an issue.
This is beside the point that you should change secret tokens/passwords/credentials anyway
since the all kind of bots that are crawling GitHub, are always active.

To confirm that lets make an experiment and before we start
lets get something straight: as much I would love to be a security researcher I am not.


## Experiment

To start an experiment we have to create a repository on GitHub with Readme
(so that it has at least initial commit). I am gonna name that repository deleted-commit-problem.
After that we need a second commit which we are gonna later remove from history - effectively delete it.

{% highlight bash %}
$ git clone git@github.com:matejc/deleted-commit-problem.git
$ cd deleted-commit-problem
$ echo "SECRET=should_not_be_commited" > foo.env
$ git add foo.env
$ git commit -m "Wooooops"
$ git push
{% endhighlight %}

Now that we have everything prepared for the experiment, we can remove last commit locally and force push.

{% highlight bash %}
$ git reset --hard HEAD^
$ git push -f
{% endhighlight %}

Lets check what git reflog looks like at this moment.

{% highlight bash %}
$ git reflog
c439e9c (HEAD -> main) HEAD@{0}: reset: moving to HEAD^
ed1420d (origin/main, origin/HEAD) HEAD@{1}: commit: Wooooops
c439e9c (HEAD -> main) HEAD@{2}: clone: from github.com:matejc/deleted-commit-problem.git
{% endhighlight %}

Git reflog shows your detailed **local** actions.
And if you - after the force push - clone again this repository, you will not see any commit with message Wooooops.

Remember the commit with message Wooooops for later: ed1420d

Lets see how [the repository](https://github.com/matejc/deleted-commit-problem) looks online, we see that we have only one commit and that is shown on the picture

![first version](/img/post/deleted-commit.png){: class="post-img"}

And lets check our deleted commit directly by editing the address bar directly, appending the **commit/ed1420d** to previously opened site:

[github.com/matejc/deleted-commit-problem/**commit/ed1420d**](https://github.com/matejc/deleted-commit-problem/commit/ed1420d)

![first version](/img/post/undeleted-commit.png){: class="post-img"}


## Conclusion

Well, at this point you could say how come would anyone know the commit hash?
Hmm, I do not know, but as you remember I am not a security researcher or anything similar,
so I am sure that someone already found a way for that since GitHub itself is huge peace of software,
I am sure that this is not the only issue that it has.

For now this is it, have fun and be happy!
