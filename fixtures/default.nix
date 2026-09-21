/*
  nix-batteries public-library fixture coordinator.

   flake.nix → this file → checks.<system>.
  It verifies public library contracts; each child fixture owns its own cases.
*/
{
  batteriesLib, # flake.nix → batteriesLib
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
  batteriesLibNames = builtins.attrNames batteriesLib;
  missingLibNames = builtins.filter (name: !(builtins.elem name batteriesLibNames)) expectedLibNames;
  unexpectedLibNames = builtins.filter (
    name: !(builtins.elem name expectedLibNames)
  ) batteriesLibNames;

  modulonFixture = batteriesLib.modulon {
    dirs = [ ./modulon/modules ];
    extraModules = [ ./modulon/extra-module.nix ];
  };
  modulonImports = map toString modulonFixture.imports;

  moduletteFixture = batteriesLib.modulette.discoverModules {
    mode = "flat";
    directory = ./modulette/modules;
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  moduletteDirectoryFixture = batteriesLib.modulette.discoverModules {
    mode = "directory";
    directory = ./modulette/hosts;
    targetFile = "host.nix";
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  # A scanned subdirectory without the target file must fail with a Modulette
  # error rather than a bare import or read error.
  moduletteMissingTargetFixture = builtins.tryEval (
    builtins.deepSeq (batteriesLib.modulette.discoverModules {
      mode = "directory";
      directory = ./modulette/hosts-missing-target;
      targetFile = "host.nix";
      args.value = "loaded";
    }) true
  );

  missingInputGuard = batteriesLib.guardFlakeInput "missing-input" { };

  # The exported theme option module is a real module function: applied with a
  # lib, it declares the selection options consumers configure per host.
  themeOptionFixture = batteriesLib.themeOptionModule { inherit lib; };
  themeOptionNames = builtins.attrNames themeOptionFixture.options.myOptions.hm.data.theme;

  dynamicAliasNames = batteriesLib.dynamicAliases.discoverNixFileNames {
    directory = ./dynamic-aliases/nix-files;
  };
  dynamicAliasMkArgs = builtins.functionArgs batteriesLib.dynamicAliases.mk;
  dynamicAliasProjectTasks = batteriesLib.dynamicAliases.mk {
    names = [
      "fmt"
      "test"
    ];
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
    legendFor = name: _: "Run project ${name}";
    groupName = "Project Tasks";
  };
  dynamicAliasEntryTasks = batteriesLib.dynamicAliases.mk {
    entries.rust = {
      command = "nix develop";
      display = "nix develop .#rust";
    };
    nameFor = name: _: "nd-${name}";
    valueFor = name: entry: "${entry.command} /workspace#${name}";
    legendFor = _: entry: entry.display;
  };
  dynamicAliasCompatTasks = batteriesLib.dynamicAliases.mk {
    names = [ "docs" ];
    metadata.owner = "external-caller";
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
  };
  dynamicAliasDuplicateCheck = builtins.tryEval (
    batteriesLib.dynamicAliases.mk {
      names = [
        "one"
        "two"
      ];
      nameFor = _: _: "dup";
      valueFor = name: _: name;
    }
  );

  dynamicAliasSelection = batteriesLib.dynamicAliases.mk {
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
    builtins.deepSeq (batteriesLib.dynamicAliases.mk {
      names = [ "absent" ];
      entries = { };
      nameFor = name: _: name;
      valueFor = _: entry: entry;
    }) true
  );

  nixOptionsToMdFixtureResult = import ./nix-options-to-md {
    inherit lib;
    nixOptionsToMd = batteriesLib.nixOptionsToMd;
  };

  rendererChecks = import ./renderers {
    inherit
      batteriesLib
      lib
      pass
      pkgs
      ;
  };
  themeChecks = import ./themes {
    inherit
      batteriesLib
      lib
      pass
      ;
  };
in
{
  modulon-boundaries = import ./modulon { inherit batteriesLib lib pass; };
  git-state-runtime = import ./git-repo-state { inherit batteriesLib lib pkgs; };
  batteriesLib-surface =
    assert missingLibNames == [ ];
    assert unexpectedLibNames == [ ];
    assert builtins.isFunction batteriesLib.themeOptionModule;
    assert
      themeOptionNames == [
        "enableColors"
        "name"
      ];
    assert themeOptionFixture.options.myOptions.hm.data.theme.name.default == "nushell-inspired";
    assert themeOptionFixture.options.myOptions.hm.data.theme.enableColors.default == null;
    pass "nix-batteries-batteriesLib-surface";

  modulon-fixture =
    assert builtins.elem (toString ./modulon/modules/valid.nix) modulonImports;
    assert builtins.elem (toString ./modulon/extra-module.nix) modulonImports;
    assert !(builtins.elem (toString ./modulon/modules/skipped.nix) modulonImports);
    pass "nix-batteries-modulon-fixture";

  modulette-fixture =
    assert builtins.attrNames moduletteFixture == [ "alpha" ];
    assert moduletteFixture.alpha.value == "loaded";
    pass "nix-batteries-modulette-fixture";

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
    pass "nix-batteries-modulette-directory-fixture";

  guard-flake-input-fixture =
    assert missingInputGuard.has == false;
    assert missingInputGuard.input == null;
    pass "nix-batteries-guard-flake-input-fixture";

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
    pass "nix-batteries-dynamic-aliases-fixture";

  nix-options-to-md-fixture =
    assert builtins.all (result: result) (builtins.attrValues nixOptionsToMdFixtureResult);
    assert nixOptionsToMdFixtureResult.hasHeader;
    assert nixOptionsToMdFixtureResult.hasEnableRow;
    assert nixOptionsToMdFixtureResult.hasPortRow;
    assert nixOptionsToMdFixtureResult.hasNestedRow;
    assert nixOptionsToMdFixtureResult.hasStringDefaultRow;
    assert nixOptionsToMdFixtureResult.customNamespace;
    assert nixOptionsToMdFixtureResult.customExcludesNested;
    pass "nix-batteries-nix-options-to-md-fixture";
}
// rendererChecks
// themeChecks
