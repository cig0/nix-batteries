/*
  nix-sidecar flake entry point.

  Plain outputs over a single nixpkgs input. sidecarLibs is a static
  attribute set mapping each public export directly onto its implementation
  under libraries/; checks and formatter fan out per supported system.
*/
{
  description = "Sidecar - A Nix flake toolkit with reusable building blocks";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forSystems = f: lib.genAttrs systems (system: f (import nixpkgs { inherit system; }));
      mkGitRepoState = args: import ./libraries/toolbox/git-repo-state args;
      sidecarLibs = {
        dynamicAliases = import ./libraries/toolbox/dynamic-aliases { inherit lib; };
        flakeRoot = self.outPath;
        gitRepoState = mkGitRepoState { };
        guardFlakeInput = import ./libraries/guard-flake-input { inherit lib; };
        helpLegendDecorator = import ./libraries/decorators/help-legend { };
        inherit mkGitRepoState;
        modulette = import ./libraries/auto-discover/modulette { inherit lib; };
        modulon = collectorArgs: import ./libraries/auto-discover/modulon { inherit lib; } collectorArgs;
        nixOptionsToMd = import ./libraries/toolbox/nix-options-to-md;
        themes = import ./libraries/themes/resolver.nix {
          flakeRoot = self.outPath;
          inherit lib;
        };
      };
    in
    {
      inherit sidecarLibs;
      checks = forSystems (
        pkgs:
        import ./fixtures { inherit sidecarLibs lib pkgs; }
        // {
          consumer-fixture =
            # Exercise the consumer through the public flake output boundary.
            assert ((import ./fixtures/consumer/flake.nix).outputs { sidecar = self; }).smoke;
            pkgs.runCommand "nix-sidecar-consumer-fixture" { } "touch $out";
        }
      );
      formatter = forSystems (pkgs: pkgs.nixfmt);
    };
}
