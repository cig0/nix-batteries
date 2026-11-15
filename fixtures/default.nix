/*
  nix-battery public-library fixture coordinator.

   flake.nix → this file → checks.<system>.
  It verifies public library contracts; each child fixture owns its own cases.
*/
{
  batteryLib, # flake.nix → batteryLib
  lib, # flake.nix → nixpkgs.lib
  pkgs, # flake.nix → per-system package set
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
    "themeOptionModule"
    "themes"
  ];
  batteryLibNames = builtins.attrNames batteryLib;
  missingLibNames = builtins.filter (name: !(builtins.elem name batteryLibNames)) expectedLibNames;
  unexpectedLibNames = builtins.filter (name: !(builtins.elem name expectedLibNames)) batteryLibNames;

  modulonFixture = batteryLib.modulon {
    dirs = [ ./modulon/modules ];
    extraModules = [ ./modulon/extra-module.nix ];
  };
  modulonImports = map toString modulonFixture.imports;

  moduletteFixture = batteryLib.modulette.discoverModules {
    mode = "flat";
    directory = ./modulette/modules;
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  moduletteDirectoryFixture = batteryLib.modulette.discoverModules {
    mode = "directory";
    directory = ./modulette/hosts;
    targetFile = "host.nix";
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  # A scanned subdirectory without the target file must fail with a Modulette
  # error rather than a bare import or read error.
  moduletteMissingTargetFixture = builtins.tryEval (
    builtins.deepSeq (batteryLib.modulette.discoverModules {
      mode = "directory";
      directory = ./modulette/hosts-missing-target;
      targetFile = "host.nix";
      args.value = "loaded";
    }) true
  );

  missingInputGuard = batteryLib.guardFlakeInput "missing-input" { };

  guardedModule =
    { _inputs, lib, ... }:
    let
      tool = _inputs.nix-battery.batteryLib.guardFlakeInput "example-tool" _inputs;
    in
    {
      imports = lib.optionals tool.has [
        tool.input.homeModules.default
        { programs.example-tool.enable = true; }
      ];
    };
  evaluateGuardedModule =
    inputs:
    lib.evalModules {
      specialArgs._inputs = inputs // {
        nix-battery.batteryLib = batteryLib;
      };
      modules = [ guardedModule ];
    };
  presentGuardedModule = evaluateGuardedModule {
    example-tool.homeModules.default = {
      options.programs.example-tool.enable = lib.mkEnableOption "example tool";
    };
  };
  absentGuardedModule = evaluateGuardedModule { };

  # The exported theme option module is a real module function: applied with a
  # lib, it declares the selection options consumers configure per host.
  themeOptionFixture = batteryLib.themeOptionModule { inherit lib; };
  themeOptionNames = builtins.attrNames themeOptionFixture.options.myOptions.hm.data.theme;

  dynamicAliasNames = batteryLib.dynamicAliases.discoverNixFileNames {
    directory = ./dynamic-aliases/nix-files;
  };
  dynamicAliasMkArgs = builtins.functionArgs batteryLib.dynamicAliases.mk;
  dynamicAliasProjectTasks = batteryLib.dynamicAliases.mk {
    names = [
      "fmt"
      "test"
    ];
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
    legendFor = name: _: "Run project ${name}";
    groupName = "Project Tasks";
  };
  dynamicAliasEntryTasks = batteryLib.dynamicAliases.mk {
    entries.rust = {
      command = "nix develop";
      display = "nix develop .#rust";
    };
    nameFor = name: _: "nd-${name}";
    valueFor = name: entry: "${entry.command} /workspace#${name}";
    legendFor = _: entry: entry.display;
  };
  dynamicAliasCompatTasks = batteryLib.dynamicAliases.mk {
    names = [ "docs" ];
    metadata.owner = "external-caller";
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
  };
  dynamicAliasDuplicateCheck = builtins.tryEval (
    batteryLib.dynamicAliases.mk {
      names = [
        "one"
        "two"
      ];
      nameFor = _: _: "dup";
      valueFor = name: _: name;
    }
  );

  dynamicAliasLazyValues = batteryLib.dynamicAliases.mk {
    names = [ "one" ];
    nameFor = name: _: name;
    valueFor = _: _: throw "alias value was forced";
  };
  dynamicAliasRepeatedNames = builtins.tryEval (
    batteryLib.dynamicAliases.mk {
      names = [
        "b"
        "a"
        "a"
        "b"
        "b"
      ];
      nameFor = name: _: name;
      valueFor = name: _: name;
    }
  );

  dynamicAliasSelection = batteryLib.dynamicAliases.mk {
    names = [
      "second"
      "first"
    ];
    entries = {
      first = "one";
      second = "two";
      ignored = "unused";
    };
    nameFor = name: _: name;
    valueFor = _: entry: entry;
  };
  dynamicAliasMissingEntry = builtins.tryEval (
    builtins.deepSeq (batteryLib.dynamicAliases.mk {
      names = [ "absent" ];
      entries = { };
      nameFor = name: _: name;
      valueFor = _: entry: entry;
    }) true
  );

  nixOptionsToMdFixtureResult = import ./nix-options-to-md {
    inherit lib;
    nixOptionsToMd = batteryLib.nixOptionsToMd;
  };

  rendererChecks = import ./renderers {
    inherit
      batteryLib
      lib
      pass
      pkgs
      ;
  };
  themeChecks = import ./themes {
    inherit
      batteryLib
      lib
      pass
      ;
  };
in
{
  modulon-boundaries = import ./modulon { inherit batteryLib lib pass; };
  git-state-runtime = import ./git-repo-state { inherit batteryLib lib pkgs; };
  batteryLib-surface =
    assert missingLibNames == [ ];
    assert unexpectedLibNames == [ ];
    assert builtins.isFunction batteryLib.themeOptionModule;
    assert
      themeOptionNames == [
        "enableColors"
        "name"
      ];
    assert themeOptionFixture.options.myOptions.hm.data.theme.name.default == "nushell-inspired";
    assert themeOptionFixture.options.myOptions.hm.data.theme.enableColors.default == null;
    pass "nix-battery-batteryLib-surface";

  modulon-fixture =
    assert builtins.elem (toString ./modulon/modules/valid.nix) modulonImports;
    assert builtins.elem (toString ./modulon/extra-module.nix) modulonImports;
    assert !(builtins.elem (toString ./modulon/modules/skipped.nix) modulonImports);
    pass "nix-battery-modulon-fixture";

  modulette-fixture =
    assert builtins.attrNames moduletteFixture == [ "alpha" ];
    assert moduletteFixture.alpha.value == "loaded";
    pass "nix-battery-modulette-fixture";

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
    assert moduletteMissingTargetFixture.success == false;
    pass "nix-battery-modulette-directory-fixture";

  guard-flake-input-fixture =
    assert missingInputGuard.has == false;
    assert missingInputGuard.input == null;
    assert presentGuardedModule.config.programs.example-tool.enable;
    assert !(absentGuardedModule.options ? programs.example-tool);
    assert absentGuardedModule.config == { };
    pass "nix-battery-guard-flake-input-fixture";

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
    assert dynamicAliasLazyValues.aliasNames == [ "one" ];
    assert dynamicAliasRepeatedNames.success == false;
    assert
      dynamicAliasSelection.names == [
        "second"
        "first"
      ];
    assert
      dynamicAliasSelection.aliases == {
        first = "one";
        second = "two";
      };
    assert !dynamicAliasMissingEntry.success;
    pass "nix-battery-dynamic-aliases-fixture";

  nix-options-to-md-fixture =
    assert builtins.all (result: result) (builtins.attrValues nixOptionsToMdFixtureResult);
    assert nixOptionsToMdFixtureResult.hasHeader;
    assert nixOptionsToMdFixtureResult.hasEnableRow;
    assert nixOptionsToMdFixtureResult.hasPortRow;
    assert nixOptionsToMdFixtureResult.hasNestedRow;
    assert nixOptionsToMdFixtureResult.hasStringDefaultRow;
    assert nixOptionsToMdFixtureResult.customNamespace;
    assert nixOptionsToMdFixtureResult.customExcludesNested;
    pass "nix-battery-nix-options-to-md-fixture";
}
// rendererChecks
// themeChecks
