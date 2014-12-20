---
layout: post
title: Too many Nix pills, I am addicted
tags:
- nixos
- nix
comments: true
---

In this blog post you are going to see how to make simple determenistic application with the power of Nix.


First of all, no offence to [Luca Bruno aka Lethalman - the inventor of Nix pills](http://lethalman.blogspot.com/)

Second of all, do not worry, Nix pills are not actual pills.

There was a joke a month back ... about an app that shows system usage of remote computer in your system tray or something like that... well I made it. Khm... apperantly all my apps start with a joke.


#### Lets start with usage

Get the code from github:

{% highlight bash %}
git clone git://github.com/matejc/cgisysinfo.git
cd cgisysinfo
{% endhighlight %}

This will build the app to Nix store:

{% highlight bash %}
nix-build --argstr prefix `pwd` \
    --argstr listenAddress "0.0.0.0" \
    --argstr listenPort "8080" \
    --argstr user "matejc" \
    --argstr password "mypassword"
{% endhighlight %}

To run the app, just execute in current folder:

{% highlight bash %}
./result/bin/cgisysinfo-run
{% endhighlight %}

To use it on remote machine you have to forward `8080/tcp` port (from example).

To test if it is working on remote machine use following command:

{% highlight bash %}
notify-send "`curl --user matejc:<your-password> -k https://<yourip>:8080/`"
{% endhighlight %}

Or just open in browser the following page: `https://<yourip>:8080/`, the browser should complain about unsecure connection but this is just because the cert is self-signed. After that you will have to enter username and password.

You could try also other scripts .. like `https://<yourip>:8080/hello.pl` or `https://<yourip>:8080/hello.py`.


#### Code

The program is in [one short file](https://github.com/matejc/cgisysinfo/blob/master/default.nix), lets go through it:

At the start we declare parameters and its default values:

1. pkgs: the root of all packages
2. prefix: where the logs, certs, unix socket, pid files lives
3. listenAddress: address, where the Nginx will listen
4. listenPort: port on which Nginx will listen
5. user: username for simpleauth, used when accessing cgi scripts with curl or something
6. password: password for simpleauth
7. templatesFile: the file where you will have templates.nix
8. extraNginxConf: if you want to add extra Nginx configuration in the `server` block

{% highlight nix linenos %}
{ pkgs ? import <nixpkgs> {}
, prefix ? "/var/lib/cgisysinfo"
, listenAddress ? "localhost"
, listenPort ? "9999"
, user ? "user"
, password ? "password"
, templatesFile ? "${prefix}/templates.nix"
, extraNginxConf ? "" }:
let
{% endhighlight %}

Now we have to create a `nginx.conf` - the web server configuration with wich we are going serve cgi scripts.

{% highlight nix linenos %}
  nginxconf = pkgs.writeText "nginx.conf" ''
  pid ${prefix}/nginx.pid;
  worker_processes 1;
  events {
    worker_connections 128;
  }
  http {
    server {
      access_log ${prefix}/cgi.access.log;
      error_log ${prefix}/cgi.error.log;

      ssl on;
      ssl_certificate     ${prefix}/ssl/selfsigned.crt;
      ssl_certificate_key ${prefix}/ssl/selfsigned.key;

      root ${scripts}/www;
      index index.sh index.pl index.py;
      listen ${listenAddress}:${listenPort};

      location ~ .(py|pl|sh)$ {
        expires -1;

        auth_basic "closed site";
        auth_basic_user_file ${htpasswd};

        gzip           off;
        fastcgi_pass   unix:${prefix}/fcgiwrap.socket;

        # include      fastcgi_params;
        fastcgi_param  QUERY_STRING       $query_string;
        fastcgi_param  REQUEST_METHOD     $request_method;
        fastcgi_param  CONTENT_TYPE       $content_type;
        fastcgi_param  CONTENT_LENGTH     $content_length;

        fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
        fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
        fastcgi_param  REQUEST_URI        $request_uri;
        fastcgi_param  DOCUMENT_URI       $document_uri;
        fastcgi_param  DOCUMENT_ROOT      $document_root;
        fastcgi_param  SERVER_PROTOCOL    $server_protocol;

        fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
        fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

        fastcgi_param  REMOTE_ADDR        $remote_addr;
        fastcgi_param  REMOTE_PORT        $remote_port;
        fastcgi_param  SERVER_ADDR        $server_addr;
        fastcgi_param  SERVER_PORT        $server_port;
        fastcgi_param  SERVER_NAME        $server_name;
      }

      ${extraNginxConf}
    }
  }
  '';
{% endhighlight %}

Set variable `socketPath` for `fcgiwrap.socket` and create file `htpasswd` for simple authentication for Nginx (when built, password will be hashed - there will be no plain text password in store).

{% highlight nix linenos %}
  socketPath = "${prefix}/fcgiwrap.socket";

  htpasswd = pkgs.stdenv.mkDerivation {
    name = "${user}-htpasswd";
    phases = "installPhase";
    installPhase = ''
      export PATH="${pkgs.openssl}/bin:$PATH"
      printf "${user}:$(openssl passwd -crypt ${password})\n" >> $out
    '';
  };
{% endhighlight %}

Here comes a bit of magic, we take `templatesFile` which we are going to see later and make python/perl/bash scripts from it.

{% highlight nix linenos %}
  scripts =
    let
      templates = import templatesFile {inherit pkgs prefix;};
      paths = map (template:
        pkgs.writeTextFile rec {
          name = "cgisysinfo-${template.name}";
          text = template.text;
          executable = true;
          destination = "/www/${template.name}";
        }) templates;
    in
      pkgs.buildEnv {
        name = "cgisysinfo-scripts";
        inherit paths;
        pathsToLink = [ "/www" ];
      };
{% endhighlight %}

Main run script takes care of starting `fcgiwrap` and `Nginx`.

{% highlight nix linenos %}
  run = pkgs.writeScriptBin "cgisysinfo-run" ''
  #!${pkgs.bash}/bin/bash

  # we send QUIT signal to Nginx when you press Ctrl+C
  function stopall() {
    kill -QUIT $( cat ${prefix}/nginx.pid )
    exit
  }
  trap "stopall" INT

  export PATH="${pkgs.fcgiwrap}/sbin:${pkgs.nginx}/bin:${pkgs.openssl}/bin:$PATH"

  # generate self-signed cert for nginx (if folder 'ssl' does not exist yet)
  test -d ${prefix}/ssl || \
    { mkdir -p ${prefix}/ssl && \
    openssl req -new -x509 -nodes -keyout ${prefix}/ssl/selfsigned.key -out ${prefix}/ssl/selfsigned.crt -subj "/C=GB/ST=London/L=London/O=Global Security/OU=IT Department/CN=example.xyz"; }

  test -S ${socketPath} && unlink ${socketPath}

  echo -e "\nExample usage:"
  echo "$ notify-send \"\`curl --user ${user}:<your-password> -k https://${listenAddress}:${listenPort}/\`\""
  echo -e "\nPress Ctrl+C to stop ..."

  # start nginx as daemon
  mkdir -p ${prefix}/var/logs
  nginx -c ${nginxconf} -p ${prefix}/var

  # start fcgiwrap (this one blocks)
  fcgiwrap -c 1 -s unix:${socketPath}
  '';
{% endhighlight %}

At the end we install `cgisysinfo-run` command to Nix store.
I also added a `shellHook` to run app with `nix-shell`.

{% highlight nix linenos %}
  cgisysinfo = pkgs.stdenv.mkDerivation rec {
    name = "cgisysinfo-${version}";
    version = "0.2";
    unpackPhase = "true";
    installPhase = ''
      mkdir -p $out/bin
      ln -s ${run}/bin/* $out/bin
    '';
    shellHook = ''
      ${run}/bin/cgisysinfo-run
    '';
  };

in cgisysinfo
{% endhighlight %}


#### `templatesFile`

This is an example of `templates.nix` which is also located on github as example. Currently only `.py`, `.pl` and `.sh` files are supported.

Ok lets make one thing clear at this point, for security reasons, be very carefull what information and how you expose on the internet, this is literally remote code execution app.

{% highlight nix linenos %}
{ pkgs, prefix }:
[

  {
    name = "index.sh";
    text = ''
      #!${pkgs.bash}/bin/bash

      export PATH="$PATH:${pkgs.procps}/bin:${pkgs.sysstat}${pkgs.sysstat}/bin"
      echo -e "Content-type: text/plain\n\n"

      echo RAM: `free -mh | awk 'NR==2{ print $3"/"$2 }'`
      echo Swap: `free -mh | awk 'NR==3{ print $3"/"$2 }'`
      ps -eo pcpu,pmem,user,args | sort -k 1 -r | awk 'NR>1 && NR<5{n=split($4,a,"/"); print a[n]": cpu:"$1"%, mem:"$2"%, u:"$3}'
      echo
    '';
  }

  {
    name = "hello.pl";
    text = ''
      #!${pkgs.perl}/bin/perl

      print "Content-type: text/html\n\n";
      print "<html><body>Hello, Perl world.</body></html>";
    '';
  }

  {
    name = "hello.py";
    text = ''
      #!${pkgs.python27}/bin/python

      print "Content-type: text/html\n\n";
      print "<html><body>Hello, Python world.</body></html>";
    '';
  }

]
{% endhighlight %}


You have seen how easy is to make a Nix application.
This is it. Happy hacking!
