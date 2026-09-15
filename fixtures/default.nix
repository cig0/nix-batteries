/*
  nix-sidecar public-library fixture coordinator.

   flake.nix → this file → checks.<system>.
  It verifies public library contracts; each child fixture owns its own cases.
*/
{
  sidecarLibs,
  lib,
  pkgs,
}:

let
  pass = name: pkgs.runCommand name { } "touch $out";

  expectedLibNames = [
    "dynamicAliases"
    "flakeRoot"
    "gitRepoState"
    "guardFlakeInput"
    "helpLegendDecorator"
    "mkGitRepoState"
    "modulette"
    "modulon"
    "nixOptionsToMd"
    "themes"
  ];
  sidecarLibNames = builtins.attrNames sidecarLibs;
  missingLibNames = builtins.filter (name: !(builtins.elem name sidecarLibNames)) expectedLibNames;
  unexpectedLibNames = builtins.filter (name: !(builtins.elem name expectedLibNames)) sidecarLibNames;

  modulonFixture = sidecarLibs.modulon {
    dirs = [ ./modulon/modules ];
    extraModules = [ ./modulon/extra-module.nix ];
  };
  modulonImports = map toString modulonFixture.imports;

  moduletteFixture = sidecarLibs.modulette.discoverModules {
    mode = "flat";
    directory = ./modulette/modules;
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  moduletteDirectoryFixture = sidecarLibs.modulette.discoverModules {
    mode = "directory";
    directory = ./modulette/hosts;
    targetFile = "host.nix";
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  missingInputGuard = sidecarLibs.guardFlakeInput "missing-input" { };

  dynamicAliasNames = sidecarLibs.dynamicAliases.discoverNixFileNames {
    directory = ./dynamic-aliases/nix-files;
  };
  dynamicAliasMkArgs = builtins.functionArgs sidecarLibs.dynamicAliases.mk;
  dynamicAliasProjectTasks = sidecarLibs.dynamicAliases.mk {
    names = [
      "fmt"
      "test"
    ];
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
    legendFor = name: _: "Run project ${name}";
    groupName = "Project Tasks";
  };
  dynamicAliasEntryTasks = sidecarLibs.dynamicAliases.mk {
    entries.rust = {
      command = "nix develop";
      display = "nix develop .#rust";
    };
    nameFor = name: _: "nd-${name}";
    valueFor = name: entry: "${entry.command} /workspace#${name}";
    legendFor = _: entry: entry.display;
  };
  dynamicAliasCompatTasks = sidecarLibs.dynamicAliases.mk {
    names = [ "docs" ];
    metadata.owner = "external-caller";
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
  };
  dynamicAliasDuplicateCheck = builtins.tryEval (
    sidecarLibs.dynamicAliases.mk {
      names = [
        "one"
        "two"
      ];
      nameFor = _: _: "dup";
      valueFor = name: _: name;
    }
  );

  nixOptionsToMdFixtureResult = import ./nix-options-to-md {
    inherit lib;
    nixOptionsToMd = sidecarLibs.nixOptionsToMd;
  };

  rendererChecks = import ./renderers {
    inherit
      sidecarLibs
      lib
      pass
      pkgs
      ;
  };
  themeChecks = import ./themes {
    inherit
      sidecarLibs
      lib
      pass
      ;
  };
in
{
  sidecarLibs-surface =
    assert missingLibNames == [ ];
    assert unexpectedLibNames == [ ];
    pass "nix-sidecar-sidecarLibs-surface";

  modulon-fixture =
    assert builtins.elem (toString ./modulon/modules/valid.nix) modulonImports;
    assert builtins.elem (toString ./modulon/extra-module.nix) modulonImports;
    assert !(builtins.elem (toString ./modulon/modules/skipped.nix) modulonImports);
    pass "nix-sidecar-modulon-fixture";

  modulette-fixture =
    assert builtins.attrNames moduletteFixture == [ "alpha" ];
    assert moduletteFixture.alpha.value == "loaded";
    pass "nix-sidecar-modulette-fixture";

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
    pass "nix-sidecar-modulette-directory-fixture";

  guard-flake-input-fixture =
    assert missingInputGuard.has == false;
    assert missingInputGuard.input == null;
    pass "nix-sidecar-guard-flake-input-fixture";

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
    pass "nix-sidecar-dynamic-aliases-fixture";

  nix-options-to-md-fixture =
    assert nixOptionsToMdFixtureResult.hasHeader;
    assert nixOptionsToMdFixtureResult.hasEnableRow;
    assert nixOptionsToMdFixtureResult.hasPortRow;
    assert nixOptionsToMdFixtureResult.hasNestedRow;
    assert nixOptionsToMdFixtureResult.customNamespace;
    assert nixOptionsToMdFixtureResult.customExcludesNested;
    pass "nix-sidecar-nix-options-to-md-fixture";
}
// rendererChecks
// themeChecks
