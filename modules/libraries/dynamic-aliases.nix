# Generic alias discovery and generation → sidecarLibs.dynamicAliases.
{ lib, ... }:
{
  flake.sidecarLibs.dynamicAliases = import ../../libraries/toolbox/dynamic-aliases {
    inherit lib;
  };
}
