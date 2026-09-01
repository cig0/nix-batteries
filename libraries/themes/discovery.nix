/*
  Provider-owned theme discovery.

  Modulette loads only files from themesDirectory whose first line begins with
  the theme-module header. The returned attribute names are the public theme
  names consumed by resolver.nix.
*/
{
  flakeRoot,
  lib,
  themesDirectory,
}:
let
  modulette = import (flakeRoot + "/libraries/auto-discover/modulette") { inherit lib; };
in
modulette.discoverModules {
  mode = "flat";
  directory = themesDirectory;
  headerPrefix = "# Theme module.";
  args = { };
}
