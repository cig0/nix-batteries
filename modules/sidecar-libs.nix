/*
  Shared option contract for the public library catalogue.

  Feature modules contribute independent, lazy exports. Each export has one
  owner; raw values preserve function and attrset contracts without deep merging.
*/
{ lib, self, ... }:
{
  options.flake.sidecarLibs = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Reusable sidecar libraries, keyed by their public export names.";
  };

  # flake-parts supplies self from the root flake inputs.
  config.flake.sidecarLibs.flakeRoot = self.outPath;
}
