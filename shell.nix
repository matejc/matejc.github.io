{ pkgs ? import <nixpkgs> {} }:
with pkgs;
mkShell {
  name = "jekyll-gh-pages";
  nativeBuildInputs = [ rubyPackages.github-pages ];
  shellHook = ''
    jekyll serve --livereload --incremental
  '';
}
