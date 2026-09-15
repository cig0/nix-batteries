/*
  Public-library checks for each supported system.

  Merged flake.sidecarLibs → fixtures/default.nix → checks.<system>.
  Fixture cases and their source trees remain owned by fixtures/.
*/
{
  config,
  lib,
  self,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      checks =
        import ../fixtures {
          sidecarLibs = config.flake.sidecarLibs;
          inherit lib pkgs;
        }
        // {
          consumer-fixture =
            # Exercise the consumer through the public flake output boundary.
            assert ((import ../fixtures/consumer/flake.nix).outputs { sidecar = self; }).smoke;
            pkgs.runCommand "nix-sidecar-consumer-fixture" { } "touch $out";
        };
    };
}
