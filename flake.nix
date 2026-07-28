{
  description = "fuel - A Nix flake toolkit with reusable building blocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      fuelLibs = rec {
        flakeRoot = self.outPath;

        guardFlakeInput = import "${self.outPath}/libraries/guard-flake-input" { inherit lib; };
        mkGitRepoState = args: import (self.outPath + "/libraries/toolbox/git-repo-state") args;
        gitRepoState = mkGitRepoState { };
        dynamicAliases = import "${self.outPath}/libraries/toolbox/dynamic-aliases" { inherit lib; };
        helpLegendDecorator = import "${self.outPath}/libraries/decorators/help-legend" { };
        modulette = import "${self.outPath}/libraries/auto-discover/modulette" { inherit lib; };
        nixOptionsToMd = import "${self.outPath}/libraries/toolbox/nix-options-to-md";
        modulon =
          collectorArgs:
          import "${self.outPath}/libraries/auto-discover/modulon" { inherit lib; } collectorArgs;
        themes = import "${self.outPath}/libraries/themes/resolver.nix" {
          flakeRoot = self.outPath;
          inherit lib;
        };
      };

      checks = forAllSystems (
        system:
        import ./fixtures {
          fuelLibs = self.fuelLibs;
          inherit lib;
          pkgs = nixpkgs.legacyPackages.${system};
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
