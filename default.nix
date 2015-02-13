{ gemfile ? ./Gemfile }:
let
  gemfile_loaded = builtins.toFile "Gemfile" (builtins.readFile gemfile);

  pkgs = import <nixpkgs> { };
  ruby = pkgs.ruby_2_1_1;
  bundler = pkgs.bundler_HEAD.override { inherit ruby; };
  rubygems = pkgs.rubygemsFun ruby;

  phaseone_gemfilelock = pkgs.stdenv.mkDerivation {
    name = "phaseone_gemfilelock";
    unpackPhase = "true";
    buildInputs = [ ruby bundler pkgs.busybox rubygems pkgs.gcc pkgs.stdenv
      pkgs.gnumake pkgs.libxml2 pkgs.libxslt ];
    GEM_PATH = pkgs.lib.makeSearchPath ruby.gemPath [ bundler rubygems ];
    buildPhase = ''
      cp ${gemfile_loaded} ./Gemfile

      # lets break some rules
      unset http_proxy
      unset ftp_proxy

      export OPENSSL_X509_CERT_FILE=${pkgs.cacert}/etc/ca-bundle.crt
      export GEM_HOME=$PWD/cache
      export HOME=$PWD
      export NIX_CFLAGS_COMPILE="-I${pkgs.libxml2}/include/libxml2 $NIX_CFLAGS_COMPILE";

      bundle config build.nokogiri -- --use-system-libraries\' --with-xslt-dir=${pkgs.libxslt} --with-xml2-dir=${pkgs.libxml2} --with-iconv-dir=${pkgs.libiconvOrLibc} --with-zlib-dir=${pkgs.zlib} --with-exslt-dir=${pkgs.libxslt}

      bundle install -j4 --verbose
    '';
    doCheck = true;
    checkPhase = ''
      test 2 -lt `wc -l < ./Gemfile.lock` || { echo "Output file is empty!" && exit 1; }
    '';
    installPhase = ''
      mkdir -p $out
      cp ./Gemfile.lock $out
      cp ./Gemfile $out
    '';
  };

  phasetwo_gemsetnix = pkgs.stdenv.mkDerivation {
    name = "phasetwo_gemfilenix";
    unpackPhase = "true";
    buildInputs = [ bundler pkgs.busybox rubygems pkgs.nix ];
    GEM_PATH = pkgs.lib.makeSearchPath ruby.gemPath [ bundler rubygems ];
    buildPhase = ''
      ln -s ${phaseone_gemfilelock}/Gemfile ./Gemfile
      ln -s ${phaseone_gemfilelock}/Gemfile.lock ./Gemfile.lock

      # lets break some rules
      unset http_proxy
      unset ftp_proxy

      export GEM_HOME=$PWD/cache
      export HOME=$PWD
      export CURL_CA_BUNDLE=${pkgs.cacert}/etc/ca-bundle.crt
      export NIX_REMOTE=daemon

      ${pkgs.bundix}/bin/bundix expr
    '';
    doCheck = true;
    checkPhase = ''
      test 2 -lt `wc -l < ./gemset.nix` || { echo "Output file is empty!" && exit 1; }
    '';
    installPhase = ''
      mkdir -p $out
      cp ./gemset.nix $out
      cp ./Gemfile $out
      cp ./Gemfile.lock $out

      substituteInPlace $out/gemset.nix \
        --replace '"ffi" = {' '"ffi" = { preInstall = "export OPENSSL_X509_CERT_FILE=${pkgs.cacert}/etc/ca-bundle.crt";'
      cat $out/gemset.nix
    '';
  };

  jekyllenv = pkgs.bundlerEnv {
    name = "jekyll-env";
    inherit ruby;
    gemset = "${phasetwo_gemsetnix}/gemset.nix";
    gemfile = "${phasetwo_gemsetnix}/Gemfile";
    lockfile = "${phasetwo_gemsetnix}/Gemfile.lock";
  };


  env = pkgs.stdenv.mkDerivation {
    name = "env";
    unpackPhase = "true";
    installPhase = ''true'';
    shellHook = ''
      export GEM_PATH="${jekyllenv}/${jekyllenv.ruby.gemPath}"
      export PATH="$GEM_PATH/bin:${ruby}/bin:${pkgs.python27}/bin:${pkgs.pythonPackages.pygments}/bin:${pkgs.nodejs}/bin:${pkgs.busybox}/bin"
      echo ${jekyllenv}
    '';
  };

in
  env
