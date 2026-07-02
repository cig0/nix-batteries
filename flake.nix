{
  description = "Fuel - A Nix flake toolkit with reusable building blocks";

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
      expectedLibNames = [
        "dynamicAliases"
        "flakeRoot"
        "gitRepoState"
        "gitRepoStateRenderer"
        "guardFlakeInput"
        "helpLegendDecorator"
        "mkGitRepoState"
        "nixOptionsToMd"
        "modulette"
        "modulon"
        "themes"
      ];
    in
    {
      fuelLibs = rec {
        flakeRoot = self.outPath;

        guardFlakeInput = import "${self.outPath}/libraries/guard-flake-input" { inherit lib; };
        mkGitRepoState = args: import (self.outPath + "/libraries/toolbox/git-repo-state") args;
        gitRepoState = mkGitRepoState { };
        gitRepoStateRenderer = {
          raw = import (self.outPath + "/libraries/toolbox/git-repo-state-renderer");
          decorated = import (self.outPath + "/libraries/toolbox/git-repo-state-renderer/decorated.nix");
        };
        dynamicAliases = import "${self.outPath}/libraries/toolbox/dynamic-aliases" { inherit lib; };
        helpLegendDecorator = import "${self.outPath}/libraries/decorators/help-legend" { };
        modulette = import "${self.outPath}/libraries/auto-discover/modulette" { inherit lib; };
        nixOptionsToMd = import "${self.outPath}/libraries/toolbox/nix-options-to-md";
        modulon =
          collectorArgs:
          import "${self.outPath}/libraries/auto-discover/modulon" { inherit lib; } collectorArgs;
        themes = import "${self.outPath}/libraries/themes/palette.nix" {
          flakeRoot = self.outPath;
          inherit lib;
        };
      };

      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pass = name: pkgs.runCommand name { } "touch $out";

          fuelLibNames = builtins.attrNames self.fuelLibs;
          missingLibNames = builtins.filter (name: !(builtins.elem name fuelLibNames)) expectedLibNames;
          unexpectedLibNames = builtins.filter (name: !(builtins.elem name expectedLibNames)) fuelLibNames;

          modulonFixture = self.fuelLibs.modulon {
            dirs = [ ./fixtures/modulon/modules ];
            extraModules = [ ./fixtures/modulon/extra-module.nix ];
          };
          modulonImports = map toString modulonFixture.imports;

          moduletteFixture = self.fuelLibs.modulette.discoverModules {
            mode = "flat";
            directory = ./fixtures/modulette/modules;
            headerText = "# Modulette fixture module. Do not remove this header.";
            args = {
              value = "loaded";
            };
          };

          moduletteDirectoryFixture = self.fuelLibs.modulette.discoverModules {
            mode = "directory";
            directory = ./fixtures/modulette/hosts;
            targetFile = "host.nix";
            headerText = "# Modulette fixture module. Do not remove this header.";
            args = {
              value = "loaded";
            };
          };

          enabledTheme = self.fuelLibs.themes.resolve {
            name = "nushell-inspired";
            enableColors = true;
          };

          disabledTheme = self.fuelLibs.themes.resolve {
            name = "nushell-inspired";
            enableColors = false;
          };

          amberTheme = self.fuelLibs.themes.resolve {
            name = "311amber";
            enableColors = true;
          };

          helpLayout = self.fuelLibs.helpLegendDecorator.sectionLayout {
            groups = [
              {
                name = "Fixture";
                cmds = [ "check" ];
              }
            ];
            descFn = _: "Run fixture check";
          };

          missingInputGuard = self.fuelLibs.guardFlakeInput "missing-input" { };

          dynamicAliasNames = self.fuelLibs.dynamicAliases.discoverNixFileNames {
            directory = ./fixtures/dynamic-aliases/nix-files;
          };

          dynamicAliasMkArgs = builtins.functionArgs self.fuelLibs.dynamicAliases.mk;

          dynamicAliasProjectTasks = self.fuelLibs.dynamicAliases.mk {
            names = [
              "fmt"
              "test"
            ];
            nameFor = name: _: "p-${name}";
            valueFor = name: _: "just ${name}";
            legendFor = name: _: "Run project ${name}";
            groupName = "Project Tasks";
          };

          dynamicAliasEntryTasks = self.fuelLibs.dynamicAliases.mk {
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

          dynamicAliasCompatTasks = self.fuelLibs.dynamicAliases.mk {
            names = [ "docs" ];
            metadata = {
              owner = "external-caller";
            };
            nameFor = name: _: "p-${name}";
            valueFor = name: _: "just ${name}";
          };

          dynamicAliasDuplicateCheck = builtins.tryEval (
            self.fuelLibs.dynamicAliases.mk {
              names = [
                "one"
                "two"
              ];
              nameFor = _: _: "dup";
              valueFor = name: _: name;
            }
          );

          nixOptionsToMdFixtureResult = import ./fixtures/nix-options-to-md {
            inherit lib;
            nixOptionsToMd = self.fuelLibs.nixOptionsToMd;
          };
        in
        {
          fuelLibs-surface =
            assert missingLibNames == [ ];
            assert unexpectedLibNames == [ ];
            pass "nix-fuel-fuelLibs-surface";

          modulon-fixture =
            assert builtins.elem (toString ./fixtures/modulon/modules/valid.nix) modulonImports;
            assert builtins.elem (toString ./fixtures/modulon/extra-module.nix) modulonImports;
            assert !(builtins.elem (toString ./fixtures/modulon/modules/skipped.nix) modulonImports);
            pass "nix-fuel-modulon-fixture";

          modulette-fixture =
            assert builtins.attrNames moduletteFixture == [ "alpha" ];
            assert moduletteFixture.alpha.value == "loaded";
            pass "nix-fuel-modulette-fixture";

          modulette-directory-fixture =
            assert
              builtins.attrNames moduletteDirectoryFixture == [
                "alpha"
                "beta"
              ];
            assert moduletteDirectoryFixture.alpha.value == "loaded";
            assert moduletteDirectoryFixture.alpha.id == "alpha";
            assert moduletteDirectoryFixture.beta.value == "loaded";
            assert moduletteDirectoryFixture.beta.id == "beta";
            pass "nix-fuel-modulette-directory-fixture";

          themes-fixture =
            assert disabledTheme.theme.bold_zero == "";
            assert disabledTheme.mode.reset == "";
            assert builtins.stringLength enabledTheme.theme.bold_zero > 0;
            assert builtins.stringLength enabledTheme.theme.zero > 0;
            # Per-theme palette resolution: 311amber uses the CRT palette
            # CRT orange (#ffb343) differs from Tailwind orange (#ff6600)
            assert builtins.stringLength amberTheme.theme.bold_zero > 0;
            assert amberTheme.theme.bold_zero != enabledTheme.theme.bold_zero;
            pass "nix-fuel-themes-fixture";

          decorator-fixture =
            assert helpLayout.descCol == 9;
            assert helpLayout.maxDescLen == 17;
            pass "nix-fuel-decorator-fixture";

          guard-flake-input-fixture =
            assert missingInputGuard.has == false;
            assert missingInputGuard.input == null;
            pass "nix-fuel-guard-flake-input-fixture";

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
            pass "nix-fuel-dynamic-aliases-fixture";

          nix-options-to-md-fixture =
            assert nixOptionsToMdFixtureResult.hasHeader;
            assert nixOptionsToMdFixtureResult.hasEnableRow;
            assert nixOptionsToMdFixtureResult.hasPortRow;
            assert nixOptionsToMdFixtureResult.hasNestedRow;
            assert nixOptionsToMdFixtureResult.customNamespace;
            assert nixOptionsToMdFixtureResult.customExcludesNested;
            pass "nix-fuel-nix-options-to-md-fixture";
        }
      );

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt);
    };
}
