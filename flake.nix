{
  description = "Ignite - A Nix flake toolkit with reusable building blocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self }:
    let
      lib = nixpkgs.lib;
    in
    {
      lib = {
        guardFlakeInput = import ./guard-flake-input { inherit lib; };
        helpLegendDecorator = import ./decorators/help-legend { };
        modulette = import ./modulette { inherit lib; };
        modulon = collectorArgs: import ./modulon { inherit lib; } collectorArgs;
        themes = import ./themes/palette.nix {
          inherit lib;
          flakeRoot = self.outPath;
        };
      };
    };
}
