# Consumer module discovery → sidecarLibs.modulon.
{ lib, ... }:
{
  flake.sidecarLibs.modulon =
    collectorArgs: import ../../libraries/auto-discover/modulon { inherit lib; } collectorArgs;
}
