---
layout: post
title: Generate package info
tags:
- nixos
- linux
- nix
comments: true
---

Generate Nix packages information with Nix expressions


#### Lets go right to it!

System requirement is [Nix](http://nixos.org/nix/).

Save [this Nix expression code](https://gist.githubusercontent.com/matejc/d189c332091f5137697e/raw/8e628f7908ec807c4bae0532be2652b6d8ea33b4/packages.nix) to `packages.nix` or some other file, every function is commented with examples:

{% highlight nix linenos %}
let
  # set allowBroken and allowUnfree to true, so that we minimize error output later on
  pkgs = import <nixpkgs> { config = { allowBroken = true; allowUnfree = true; }; };

  # catch exceptions on isDerivation function
  tryDrv = a: builtins.tryEval (pkgs.lib.isDerivation a);
  isDerivation = a: let t = tryDrv a; in t.success && t.value == true;

  # catch exceptions on isAttrs function
  tryAttrs = a: builtins.tryEval (pkgs.lib.isAttrs a);
  isAttrs = a: let t = tryAttrs a; in t.success && t.value == true;

  # iterate through attributeset's names (one-level deep)
  # example:
  # mapValues (name: value: name) pkgs
  # => [ "bash" "zsh" "gitFull" ... ]
  mapValues = f: set: (
    map (attr: f attr (builtins.getAttr attr set)) (builtins.attrNames set)
  );

  # recurse into attributeset (search for derivations)
  # example #1:
  # mapAttrsRecursiveDrv
  #   (path: value: path) pkgs.pythonPackages ["pkgs" "pythonPackages"] []
  # => [ [ "pkgs" "pythonPackages" "searx" ] [ "pkgs" "pythonPackages" "tarman" ] ... ]
  # example #2:
  # mapAttrsRecursiveDrv (path: value: path) pkgs ["pkgs"] []
  # => [ [ "pkgs" "bash" ] [ "pkgs" "zsh" ] [ "pkgs" "pythonPackages" "searx" ] [ "pkgs" "pythonPackages" "tarman" ] ... ]
  mapAttrsRecursiveDrv = f: set: path: list:
    let
      recurse = path: set: visitList:
        let
          visitedFun = a: path:
            let
              isAtt = isAttrs a;
              isDrv = isDerivation a;
              success = if isAtt && !isDrv then pkgs.lib.any (
                element: element == a
              ) visitList else false;
              not = !success;
              list = if not then (visitList ++ [a]) else visitList;
            in
              { inherit list not isAtt isDrv; };

          g = name: value:
            let
              visited = visitedFun value path;
            in
            if visited.isDrv then
              f (path ++ [name]) value
            else if (visited.not) && (checkForEnterable value) then
              recurse (path ++ [name]) value visited.list
            else
              {
                error = "not derivation or not enterable";
                attrPath = pkgs.lib.concatStringsSep "." (path ++ [name]);
              };
        in mapValues g set;
    in (recurse path set list);

  # check if attributeste has attribute named "recurseForDerivations"
  #   therefore has derivations
  # examples:
  # checkForEnterable pkgs.bash => false
  # checkForEnterable pkgs.pythonPackages => true
  checkForEnterable = a:
    let
      t = builtins.tryEval (
        (pkgs.lib.isAttrs a) &&
        (pkgs.lib.hasAttr "recurseForDerivations" a)
      );
    in
      (t.success && t.value == true);

  # main function
  # example:
  # recurseInto "pkgs.pythonPackages"
  # => [
  #   { attrPath = "pkgs.pythonPackages.tarman"; name = "python2.7-tarman-0.1.3"; out = "/nix/store/<hash>-python2.7-tarman-0.1.3"; }
  #   { attrPath = "pkgs.pythonPackages.searx"; name = "python2.7-searx-dev"; out = "/nix/store/<hash>-python2.7-searx-dev"; }
  #   { attrPath = "pkgs.pythonPackages.isPy27"; error = "not derivation or not enterable"; }
  # ]
  recurseInto = attrPath:
    let
      path = pkgs.lib.splitString "." attrPath;
      attrs = pkgs.lib.getAttrFromPath path pkgs;
    in
      pkgs.lib.flatten (mapAttrsRecursiveDrv
        (path: value:
          let
            attrPath = pkgs.lib.concatStringsSep "." path;
            tOutPath = builtins.tryEval value.outPath;
            tName = builtins.tryEval value.name;
          in
            (if tOutPath.success && tName.success then
              { out = tOutPath.value; name = tName.value; inherit attrPath; }
            else
              { error = "tryEval failed"; inherit attrPath; })
        )
        attrs
        path
        []);

  # just strips away values with attribute "error"
  removeErrors = builtins.filter (x: (if pkgs.lib.hasAttr "error" x then
      (builtins.trace "error '${x.error}' at attribute ${x.attrPath}" false)
    else true));

in
  removeErrors (recurseInto "pkgs")
{% endhighlight %}

And run it as:

{% highlight bash %}
$ nix-instantiate packages.nix --eval --strict --show-trace
{% endhighlight %}

It should take up to 15 seconds (well that depends on your system).

#### Output

Output should look like this, but much more of it (around 3MB if you redirect the stdout to file):

{% highlight nix %}
[
    {
        attrPath = "pkgs.pythonPackages.tarman";
        name = "python2.7-tarman-0.1.3";
        out = "/nix/store/<hash>-python2.7-tarman-0.1.3";
    } {
        attrPath = "pkgs.pythonPackages.searx";
        name = "python2.7-searx-dev";
        out = "/nix/store/<hash>-python2.7-searx-dev";
    } {
        attrPath = "pkgs.pythonPackages.isPy27";
        error = "not derivation or not enterable";
    }
    .
    .
    .
]
{% endhighlight %}

Every valid item in list has `attrPath` which represent attribute path in `pkgs` structure.

If there are some errors, they will be in `error` attribute, always beside `attrPath`.
There are two error messages currently:

1. `not derivation or not enterable`: when attribute set can not be recursable further.

2. `tryEval failed`: when there is eval error on attribute.outPath or attribute.name.


And if there is no error for that package, following attributes are available:

1. `attrPath`: path, with `.` seperators, this can be used for package id (this never changes per package).

2. `name`: package name with version.

3. `out`: out path, this can be used as as unique id further on (can be different per same version of package).


#### Conclusion

The last line of `packages.nix` code can be changed from

{% highlight nix %}
removeErrors (recurseInto "pkgs")
{% endhighlight %}

to

{% highlight nix %}
builtins.toJSON (removeErrors (recurseInto "pkgs"))
{% endhighlight %}

to get JSON encoded string to feed data to some other application.

If you need some other info beside `attrPath`, `name` and `out`, just add attributes around the line `96`. For example if you want to add `meta` attribute add `meta = value.meta;` like so:

{% highlight nix %}
{ out = tOutPath.value; name = tName.value; inherit attrPath; meta = value.meta; }
{% endhighlight %}

But beware, this can increase output data size correspondly.

This is it ...

.. and feel free to leave a comment.
