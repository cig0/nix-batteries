# Theme resolution and provenance → sidecarLibs.themes.
{ lib, self, ... }:
{
  flake.sidecarLibs.themes = import ../../libraries/themes/resolver.nix {
    # flake-parts supplies the same root used by sidecarLibs.flakeRoot.
    flakeRoot = self.outPath;
    inherit lib;
  };
}
