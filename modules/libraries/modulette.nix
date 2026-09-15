# Header-validated passive discovery → sidecarLibs.modulette.
{ lib, ... }:
{
  flake.sidecarLibs.modulette = import ../../libraries/auto-discover/modulette {
    inherit lib;
  };
}
