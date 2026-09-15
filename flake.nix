/*
  nix-sidecar flake entry point.

  inputs → flake-parts → modules/* → public outputs.
  Only modules/ is auto-imported; libraries/ and fixtures/ retain their own
  import contracts.
*/
{
  description = "Sidecar - A Nix flake toolkit with reusable building blocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      # Module evaluation and public libraries share the pinned nixpkgs lib.
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:denful/import-tree";
  };

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
}
