---
layout: post
title: Image re-size
tags:
- cli
---

Re-size of jpg/jpeg images command.


I have written a small bash script that re-sizes images with jpeg or jpg file extension. It will process all images in the current working directory and all sub-directories, images will not be replaced, but saved to temp folder.

Usage examples:

This will re-size images to 500px width (will keep aspect ratio):

{% highlight bash %}
$ resizejpgs 500
{% endhighlight %}

This will make the images smaller by 40% of original image size:

{% highlight bash %}
$ resizejpgs 60%
{% endhighlight %}

[Here is the script.](https://github.com/matejc/helper_scripts/blob/master/bin/resizejpgs)

(do not forget to add it to some .../bin/ folder and make it executable)
