{ gemfile ? ./Gemfile }:
let
  gemfile_loaded = builtins.toFile "Gemfile" (builtins.readFile gemfile);

  config = {
    packageOverrides = pkgs : rec {
      ruby = pkgs.ruby_2_1;
    };
  };
  pkgs = import <nixpkgs> { inherit config; };

  phaseone_gemfilelock = pkgs.stdenv.mkDerivation {
    name = "phaseone_gemfilelock";
    unpackPhase = "true";
    buildInputs = with pkgs; [ rubyLibs.bundler busybox rubygems gcc stdenv gnumake libxml2 libxslt ];
    GEM_PATH = pkgs.lib.makeSearchPath pkgs.ruby.gemPath [ pkgs.rubyLibs.bundler pkgs.rubygems ];
    buildPhase = ''
      cp ${gemfile_loaded} ./Gemfile

      # lets break some rules
      unset http_proxy
      unset ftp_proxy

      export OPENSSL_X509_CERT_FILE=${pkgs.cacert}/etc/ca-bundle.crt
      export GEM_HOME=$PWD
      export HOME=$PWD
      export NIX_CFLAGS_COMPILE="-I${pkgs.libxml2}/include/libxml2 $NIX_CFLAGS_COMPILE";

      bundle config build.nokogiri -- --use-system-libraries\' --with-xslt-dir=${pkgs.libxslt} --with-xml2-dir=${pkgs.libxml2} --with-iconv-dir=${pkgs.libiconvOrLibc} --with-zlib-dir=${pkgs.zlib} --with-exslt-dir=${pkgs.libxslt}

      ls -lah ./.bundle
      cat ./.bundle/config

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
      cp -r ./specifications $out/specifications
    '';
  };

  phasetwo_gemfilenix = pkgs.stdenv.mkDerivation {
    name = "phasetwo_gemfilenix";
    unpackPhase = "true";
    buildInputs = with pkgs; [ rubyLibs.bundler busybox rubygems ];
    GEM_PATH = pkgs.lib.makeSearchPath pkgs.ruby.gemPath [ pkgs.rubyLibs.bundler pkgs.rubygems ];
    buildPhase = ''
      ln -s ${phaseone_gemfilelock}/Gemfile ./Gemfile
      ln -s ${phaseone_gemfilelock}/Gemfile.lock ./Gemfile.lock

      # lets break some rules
      unset http_proxy
      unset ftp_proxy

      export GEM_HOME=$PWD
      export HOME=$PWD

      ${pkgs.bundler2nix}/bin/bundler2nix Gemfile.lock Gemfile.nix
    '';
    doCheck = true;
    checkPhase = ''
      test 2 -lt `wc -l < ./Gemfile.nix` || { echo "Output file is empty!" && exit 1; }
    '';
    installPhase = ''
      mkdir -p $out
      cp ./Gemfile.nix $out
      cp ./Gemfile $out
      cp ./Gemfile.lock $out
    '';
  };

  gemsnix = map (gem: pkgs.fetchurl { url=gem.url; sha256=gem.hash; }) (import "${phasetwo_gemfilenix}/Gemfile.nix");
  phasethree_nixgems = pkgs.stdenv.mkDerivation {
    name = "phasethree_nixgems";
    unpackPhase = "true";
    buildInputs = with pkgs; [ rubyLibs.bundler busybox rubygems ];
    GEM_PATH = pkgs.lib.makeSearchPath pkgs.ruby.gemPath [ pkgs.rubyLibs.bundler pkgs.rubygems ];
    buildPhase = ''
      ln -s ${phasetwo_gemfilenix}/* .

      # lets break some rules
      unset http_proxy
      unset ftp_proxy

      export OPENSSL_X509_CERT_FILE=${pkgs.cacert}/etc/ca-bundle.crt
      export GEM_HOME=$PWD
      export HOME=$PWD

      export NIX_CFLAGS_COMPILE="-I${pkgs.libxml2}/include/libxml2 $NIX_CFLAGS_COMPILE";

      mkdir -p vendor/cache
      ${pkgs.lib.concatStrings (map (gem: "ln -s ${gem} vendor/cache/${gem.name};") gemsnix)}

      bundle config build.nokogiri -- --use-system-libraries\' --with-xslt-dir=${pkgs.libxslt} --with-xml2-dir=${pkgs.libxml2} --with-iconv-dir=${pkgs.libiconvOrLibc} --with-zlib-dir=${pkgs.zlib} --with-exslt-dir=${pkgs.libxslt}

      bundle install -j4 --verbose --local --deployment --without development test
    '';
    doCheck = true;
    checkPhase = ''
      test 2 -lt `wc -l < ./Gemfile.nix` || { echo "Output file is empty!" && exit 1; }
    '';
    installPhase = ''
      mkdir -p $out
      cp ./Gemfile.nix $out
      cp ./Gemfile $out
      cp -r ./vendor $out/vendor
    '';
  };

  env = pkgs.stdenv.mkDerivation {
    name = "env";
    unpackPhase = "true";
    installPhase = ''true'';
    shellHook = ''
      export GEM_PATH="`dirname ${phasethree_nixgems}/vendor/bundle/ruby/*/gems`"
      export PATH="$GEM_PATH/bin:${pkgs.ruby}/bin:${pkgs.python27}/bin:${pkgs.pythonPackages.pygments}/bin:${pkgs.nodejs}/bin:${pkgs.busybox}/bin"
      echo ${phasethree_nixgems}
    '';
  };

in
  env
