/*
  nix-batteries flake entry point.

  Plain outputs over a single nixpkgs input. batteriesLib is a static
  attribute set mapping each public export directly onto its implementation
  under libraries/; checks and formatter fan out per supported system.
*/
{
  description = "nix-batteries - A Nix flake toolkit with reusable building blocks";

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
      mkGitRepoState = args: import (self.outPath + "/libraries/toolbox/git-repo-state") args;
      batteriesLib = {
        dynamicAliases = import (self.outPath + "/libraries/toolbox/dynamic-aliases") { inherit lib; };
        flakeRoot = self.outPath;
        gitRepoState = mkGitRepoState { };
        guardFlakeInput = import (self.outPath + "/libraries/guard-flake-input") { inherit lib; };
        helpLegendDecorator = import (self.outPath + "/libraries/decorators/help-legend") { };
        inherit mkGitRepoState;
        modulette = import (self.outPath + "/libraries/auto-discover/modulette") { inherit lib; };
        modulon =
          collectorArgs:
          import (self.outPath + "/libraries/auto-discover/modulon") { inherit lib; } collectorArgs;
        nixOptionsToMd = import (self.outPath + "/libraries/toolbox/nix-options-to-md");
        themeOptionModule = import (self.outPath + "/libraries/themes/default.nix");
        themes = import (self.outPath + "/libraries/themes/resolver.nix") {
          flakeRoot = self.outPath;
          inherit lib;
        };
      };
    in
    {
      inherit batteriesLib;
      checks = forSystems (
        pkgs:
        import (self.outPath + "/fixtures") { inherit batteriesLib lib pkgs; }
        // {
          consumer-fixture =
            # Exercise the consumer through the public flake output boundary.
            assert ((import (self.outPath + "/fixtures/consumer/flake.nix")).outputs { sidecar = self; }).smoke;
            pkgs.runCommand "nix-batteries-consumer-fixture" { } "touch $out";
        }
      );
      formatter = forSystems (pkgs: pkgs.nixfmt);
    };
}
