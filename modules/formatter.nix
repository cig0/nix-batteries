# flake-parts supplies each system's pinned nixpkgs package set.
{
  perSystem = { pkgs, ... }: { formatter = pkgs.nixfmt; };
}
