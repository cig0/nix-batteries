# Optional input handling → sidecarLibs.guardFlakeInput.
{ lib, ... }:
{
  flake.sidecarLibs.guardFlakeInput = import ../../libraries/guard-flake-input {
    inherit lib;
  };
}
