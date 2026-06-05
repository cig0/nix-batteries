{
  description = "Ignite - A Nix flake toolkit with reusable building blocks";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { nixpkgs, self }:
    let
      flakeRoot = self.outPath;
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
      expectedLibNames = [
        "flakeRoot"
        "gitRepoState"
        "gitRepoStateRenderer"
        "guardFlakeInput"
        "helpLegendDecorator"
        "mkGitRepoState"
        "modulette"
        "modulon"
        "themes"
      ];
    in
    {
      igniteLibs = rec {
        inherit flakeRoot;

        guardFlakeInput = import "${flakeRoot}/guard-flake-input" { inherit lib; };
        mkGitRepoState = args: import (flakeRoot + "/toolbox/git-repo-state") args;
        gitRepoState = mkGitRepoState { };
        gitRepoStateRenderer = {
          raw = import (flakeRoot + "/toolbox/git-repo-state-renderer");
          decorated = import (flakeRoot + "/toolbox/git-repo-state-renderer/decorated.nix");
        };
        helpLegendDecorator = import "${flakeRoot}/decorators/help-legend" { };
        modulette = import "${flakeRoot}/modulette" { inherit lib; };
        modulon = collectorArgs: import "${flakeRoot}/modulon" { inherit lib; } collectorArgs;
        themes = import "${flakeRoot}/themes/palette.nix" { inherit flakeRoot lib; };
      };

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pass = name: pkgs.runCommand name { } "touch $out";

          igniteLibNames = builtins.attrNames self.igniteLibs;
          missingLibNames = builtins.filter (name: !(builtins.elem name igniteLibNames)) expectedLibNames;
          unexpectedLibNames = builtins.filter (name: !(builtins.elem name expectedLibNames)) igniteLibNames;

          modulonFixture = self.igniteLibs.modulon {
            dirs = [ ./fixtures/modulon/modules ];
            extraModules = [ ./fixtures/modulon/extra-module.nix ];
          };
          modulonImports = map toString modulonFixture.imports;

          moduletteFixture = self.igniteLibs.modulette.discoverModules {
            directory = ./fixtures/modulette/modules;
            headerText = "# Modulette fixture module. Do not remove this header.";
            args = {
              value = "loaded";
            };
          };

          disabledTheme = self.igniteLibs.themes.resolve {
            name = "nushell-inspired";
            enableAnsi = false;
          };

          helpLayout = self.igniteLibs.helpLegendDecorator.sectionLayout {
            groups = [
              {
                name = "Fixture";
                cmds = [ "check" ];
              }
            ];
            descFn = _: "Run fixture check";
          };

          missingInputGuard = self.igniteLibs.guardFlakeInput "missing-input" { };
        in
        {
          igniteLibs-surface =
            assert missingLibNames == [ ];
            assert unexpectedLibNames == [ ];
            pass "nix-ignite-igniteLibs-surface";

          modulon-fixture =
            assert builtins.elem (toString ./fixtures/modulon/modules/valid.nix) modulonImports;
            assert builtins.elem (toString ./fixtures/modulon/extra-module.nix) modulonImports;
            assert !(builtins.elem (toString ./fixtures/modulon/modules/skipped.nix) modulonImports);
            pass "nix-ignite-modulon-fixture";

          modulette-fixture =
            assert builtins.attrNames moduletteFixture == [ "alpha" ];
            assert moduletteFixture.alpha.value == "loaded";
            pass "nix-ignite-modulette-fixture";

          themes-fixture =
            assert disabledTheme.theme.bold_zero == "";
            assert disabledTheme.mode.reset == "";
            pass "nix-ignite-themes-fixture";

          decorator-fixture =
            assert helpLayout.descCol == 9;
            assert helpLayout.maxDescLen == 17;
            pass "nix-ignite-decorator-fixture";

          guard-flake-input-fixture =
            assert missingInputGuard.has == false;
            assert missingInputGuard.input == null;
            pass "nix-ignite-guard-flake-input-fixture";
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);
    };
}
