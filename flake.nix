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
        "dynamicAliases"
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
        dynamicAliases = import "${flakeRoot}/toolbox/dynamic-aliases" { inherit lib; };
        helpLegendDecorator = import "${flakeRoot}/decorators/help-legend" { };
        modulette = import "${flakeRoot}/auto-discover/modulette" { inherit lib; };
        modulon = collectorArgs: import "${flakeRoot}/auto-discover/modulon" { inherit lib; } collectorArgs;
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

          enabledTheme = self.igniteLibs.themes.resolve {
            name = "nushell-inspired";
            enableColors = true;
          };

          disabledTheme = self.igniteLibs.themes.resolve {
            name = "nushell-inspired";
            enableColors = false;
          };

          amberTheme = self.igniteLibs.themes.resolve {
            name = "311amber";
            enableColors = true;
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

          dynamicAliasNames = self.igniteLibs.dynamicAliases.discoverNixFileNames {
            directory = ./fixtures/dynamic-aliases/nix-files;
          };

          dynamicAliasMkArgs = builtins.functionArgs self.igniteLibs.dynamicAliases.mk;

          dynamicAliasProjectTasks = self.igniteLibs.dynamicAliases.mk {
            names = [
              "fmt"
              "test"
            ];
            nameFor = name: _: "p-${name}";
            valueFor = name: _: "just ${name}";
            legendFor = name: _: "Run project ${name}";
            groupName = "Project Tasks";
          };

          dynamicAliasEntryTasks = self.igniteLibs.dynamicAliases.mk {
            entries = {
              rust = {
                command = "nix develop";
                display = "nix develop .#rust";
              };
            };
            nameFor = name: _: "nd-${name}";
            valueFor = name: entry: "${entry.command} /workspace#${name}";
            legendFor = _: entry: entry.display;
          };

          dynamicAliasCompatTasks = self.igniteLibs.dynamicAliases.mk {
            names = [ "docs" ];
            metadata = {
              owner = "external-caller";
            };
            nameFor = name: _: "p-${name}";
            valueFor = name: _: "just ${name}";
          };

          dynamicAliasDuplicateCheck = builtins.tryEval (
            self.igniteLibs.dynamicAliases.mk {
              names = [
                "one"
                "two"
              ];
              nameFor = _: _: "dup";
              valueFor = name: _: name;
            }
          );
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
            assert builtins.stringLength enabledTheme.theme.bold_zero > 0;
            assert builtins.stringLength enabledTheme.theme.zero > 0;
            # Per-theme palette resolution: 311amber uses the CRT palette
            # CRT orange (#ffb343) differs from Tailwind orange (#ff6600)
            assert builtins.stringLength amberTheme.theme.bold_zero > 0;
            assert amberTheme.theme.bold_zero != enabledTheme.theme.bold_zero;
            pass "nix-ignite-themes-fixture";

          decorator-fixture =
            assert helpLayout.descCol == 9;
            assert helpLayout.maxDescLen == 17;
            pass "nix-ignite-decorator-fixture";

          guard-flake-input-fixture =
            assert missingInputGuard.has == false;
            assert missingInputGuard.input == null;
            pass "nix-ignite-guard-flake-input-fixture";

          dynamic-aliases-fixture =
            assert
              dynamicAliasNames == [
                "alpha"
                "beta"
              ];
            assert dynamicAliasMkArgs.names == true;
            assert dynamicAliasMkArgs.entries == true;
            assert dynamicAliasMkArgs.nameFor == false;
            assert dynamicAliasMkArgs.valueFor == false;
            assert
              dynamicAliasProjectTasks.names == [
                "fmt"
                "test"
              ];
            assert
              dynamicAliasProjectTasks.aliasNames == [
                "p-fmt"
                "p-test"
              ];
            assert dynamicAliasProjectTasks.aliases.p-fmt == "just fmt";
            assert dynamicAliasProjectTasks.aliases.p-test == "just test";
            assert dynamicAliasProjectTasks.legend.p-fmt == "Run project fmt";
            assert dynamicAliasProjectTasks.legend.p-test == "Run project test";
            assert
              dynamicAliasProjectTasks.group == {
                name = "Project Tasks";
                cmds = [
                  "p-fmt"
                  "p-test"
                ];
              };
            assert dynamicAliasEntryTasks.aliases.nd-rust == "nix develop /workspace#rust";
            assert dynamicAliasEntryTasks.legend.nd-rust == "nix develop .#rust";
            assert dynamicAliasEntryTasks.group == null;
            assert dynamicAliasCompatTasks.aliases.p-docs == "just docs";
            assert dynamicAliasDuplicateCheck.success == false;
            pass "nix-ignite-dynamic-aliases-fixture";
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
