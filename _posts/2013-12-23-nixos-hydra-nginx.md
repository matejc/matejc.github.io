---
layout: post
title: NixOS + Hydra + Nginx
tags:
- nixos
- hydra
- nginx
comments: true
---

Setup Hydra - the build server - on NixOS with Nginx


[NixOS](http://nixos.org/nixos/) is very special operating system which uses functional packagemanager called [Nix](http://nixos.org/nix/), I bet that it does not mean much to you if you do not know how it works.. well here is a quick intro: to install NixOS you need to format the disk, make partitions, then write the configuration file for NixOS and run one command and system will build itself. When you want to change this system configuration, just edit the file and rerun the rebuild command anytime, it is very much like zc.buildout.

[Hydra](http://nixos.org/hydra/) is a build farm for NixOS. Why NixOS needs a build farm, one reason is that every packet has its prefix like so `/nix/store/<hash>-<packetname>-<version>/`. That way you can have many versions of the same packet installed, without interference from each other, which is very useful for developers.

Well, Hydra can be used and abused for many things which I will write on this blog a bit later. Hydra can build any packet you can think of and on success it can run tests and on their success, build documentation, test coverage report, binary tarball, source tarball, with a bit of struggle you can build deb or rpm packets and off course all available on Hydra's server which you can setup yourself on your server.

[I have my Hydra here.](http://hydra.matejc.com/)

Here is the configuration.nix (edit as necessary):

{% highlight nix %}
{ config, pkgs, ... }:
let
  # make sure we always have the latest module
  hydra = pkgs.fetchgit {
    url = https://github.com/NixOS/hydra;
    rev = "refs/heads/master";
  };
in {

  ...

  require = [ "${hydra}/hydra-module.nix" ];

  ...


  services = {
    # for sending emails (optional)
    postfix = {
      enable = true;
      setSendmail = true;
    };

    # you are probably going to need openssh server
    openssh = {
      enable = true;
      permitRootLogin = "no";
      passwordAuthentication = false;
    };

    # actual Hydra config
    hydra = {
      enable = true;
      dbi = "dbi:Pg:dbname=hydra;host=localhost;user=hydra;";
      package = (import "${hydra}/release.nix" {}).build.x86_64-linux;
      hydraURL = "http://hydra.scriptores.com/";
      listenHost = "localhost";
      port = 3000;
      minimumDiskFree = 5;  # in GB
      minimumDiskFreeEvaluator = 2;
      notificationSender = "hydra@yourserver.com";
      logo = null;
      debugServer = false;
    };
    # Hydra requires postgresql to run
    postgresql.enable = true;
    postgresql.package = pkgs.postgresql;

    # frontend http/https server
    nginx.enable = true;
    nginx.config = pkgs.lib.readFile /root/nginx.conf;
  };
  ...
}
{% endhighlight %}


This is main configuration file for Nginx (stored in /root/nginx.conf)

{% highlight nginx %}
#user  nobody;
worker_processes  1;

error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  logs/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    include /root/hydra.nginx;

}
{% endhighlight %}


We also need the included file hydra.nginx (stored in /root/hydra.nginx)

{% highlight nginx %}
# ssl, mostly for people that are going to need to login to Hydra,
#      we do not want to send passwords as plain text
server {
    listen 0.0.0.0:443 ssl;
    server_name hydra-ssl.scriptores.com;
    keepalive_timeout    70;

    ssl_session_cache    shared:SSL:10m;
    ssl_session_timeout  10m;
    ssl_certificate     /root/ssl/hydra.crt;
    ssl_certificate_key /root/ssl/hydra.key;

    ### We want full access to SSL via backend ###
    location / {
        proxy_pass http://127.0.0.1:3000/;

        ### force timeouts if one of backend is died ##
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;

        ### Set headers ####
        proxy_set_header        Accept-Encoding   "";
        proxy_set_header        Host            $host;
        proxy_set_header        X-Real-IP       $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;

        ### Most PHP, Python, Rails, Java App can use this header ###
        #proxy_set_header X-Forwarded-Proto https;##
        #This is better##
        proxy_set_header        X-Forwarded-Proto $scheme;
        add_header              Front-End-Https   on;

        ### By default we don't want to redirect it ####
        proxy_redirect     off;
    }
}

# redirect http to https
server {
    listen 0.0.0.0:80;
    server_name hydra-ssl.scriptores.com;
    rewrite ^ https://$server_name$request_uri? permanent;
}

# for normal folks
server {
    listen 0.0.0.0:80;
    server_name hydra.scriptores.com;

    location / {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header        Host            $host;
        proxy_set_header        X-Real-IP       $remote_addr;
        proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
{% endhighlight %}

Generate self signed certificate and save files to /root/ssl/ (make sure that .key file is not world readable and that CN is your actual domain!)

{% highlight bash %}
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 -keyout hydra.key -out hydra.crt
{% endhighlight %}

Make sure you have /var/lib/hydra/.pgpass file, with this contents

{% highlight bash %}
localhost:*:*:hydra:yourHydraPgPassword
{% endhighlight %}

PostgreSQL configuration

{% highlight bash %}
$ sudo -u postgres createuser hydra -P
Enter password for new role:
Enter it again:
Shall the new role be a superuser? (y/n) n
Shall the new role be allowed to create databases? (y/n) n
Shall the new role be allowed to create more new roles? (y/n) n

$ sudo -u postgres createdb -O hydra hydra

$ echo "GRANT ALL ON DATABASE hydra TO hydra;" | sudo -u postgres psql hydra
{% endhighlight %}

You need to init the database now.. You have to do this after each upgrade also, fortunately this is easy, run this:

{% highlight bash %}
hydra-init
{% endhighlight %}

Additional links:

[Installing Hydra on Ubuntu](https://nixos.org/wiki/Installing_Hydra_on_Ubuntu)

[Also this is very usefull!](http://hydra.nixos.org/job/hydra/trunk/tarball/latest/download-by-type/doc/manual)
