---
layout: post
title: Files for OpenVPN
tags:
- openvpn
---

I used this to generate my OpenVPN certs and keys.

{% highlight bash %}
mkdir -p demoCA/newcerts
mkdir demoCA/private
echo "01" > demoCA/serial
touch demoCA/index.txt
{% endhighlight %}

under Common Name enter your correct domain:

{% highlight bash %}
openssl req -nodes -new -x509 -keyout my-ca.key -out my-ca.crt -days 3650
{% endhighlight %}

move files

{% highlight bash %}
mv my-ca.key ./demoCA/private/cakey.pem
mv my-ca.crt ./demoCA/cacert.pem
{% endhighlight %}

for server:

create private key (under Common Name enter your correct domain):

{% highlight bash %}
openssl req -nodes -new -keyout server.key -out server.csr
{% endhighlight %}

create a public key certificate and sign it

{% highlight bash %}
openssl ca -out server.crt -in server.csr
{% endhighlight %}

for client: create private key (under Common Name enter your correct domain):

{% highlight bash %}
openssl req -nodes -new -keyout <name>.key -out <name>.csr
{% endhighlight %}

set 'unique_subject = no'

{% highlight bash %}
nano demoCA/index.txt.attr
{% endhighlight %}

create a public key certificate and sign it

{% highlight bash %}
openssl ca -out <name>.crt -in <name>.csr
{% endhighlight %}

generate additional files:

{% highlight bash %}
openssl dhparam -out dh2048.pem 2048
openvpn --genkey --secret ta.key
{% endhighlight %}
