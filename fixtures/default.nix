{
  nitroLibs,
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
  nitroLibNames = builtins.attrNames nitroLibs;
  missingLibNames = builtins.filter (name: !(builtins.elem name nitroLibNames)) expectedLibNames;
  unexpectedLibNames = builtins.filter (name: !(builtins.elem name expectedLibNames)) nitroLibNames;

  modulonFixture = nitroLibs.modulon {
    dirs = [ ./modulon/modules ];
    extraModules = [ ./modulon/extra-module.nix ];
  };
  modulonImports = map toString modulonFixture.imports;

  moduletteFixture = nitroLibs.modulette.discoverModules {
    mode = "flat";
    directory = ./modulette/modules;
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  moduletteDirectoryFixture = nitroLibs.modulette.discoverModules {
    mode = "directory";
    directory = ./modulette/hosts;
    targetFile = "host.nix";
    headerText = "# Modulette fixture module. Do not remove this header.";
    args.value = "loaded";
  };

  missingInputGuard = nitroLibs.guardFlakeInput "missing-input" { };

  dynamicAliasNames = nitroLibs.dynamicAliases.discoverNixFileNames {
    directory = ./dynamic-aliases/nix-files;
  };
  dynamicAliasMkArgs = builtins.functionArgs nitroLibs.dynamicAliases.mk;
  dynamicAliasProjectTasks = nitroLibs.dynamicAliases.mk {
    names = [
      "fmt"
      "test"
    ];
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
    legendFor = name: _: "Run project ${name}";
    groupName = "Project Tasks";
  };
  dynamicAliasEntryTasks = nitroLibs.dynamicAliases.mk {
    entries.rust = {
      command = "nix develop";
      display = "nix develop .#rust";
    };
    nameFor = name: _: "nd-${name}";
    valueFor = name: entry: "${entry.command} /workspace#${name}";
    legendFor = _: entry: entry.display;
  };
  dynamicAliasCompatTasks = nitroLibs.dynamicAliases.mk {
    names = [ "docs" ];
    metadata.owner = "external-caller";
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
  };
  dynamicAliasDuplicateCheck = builtins.tryEval (
    nitroLibs.dynamicAliases.mk {
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
    nixOptionsToMd = nitroLibs.nixOptionsToMd;
  };

  rendererChecks = import ./renderers {
    inherit
      nitroLibs
      lib
      pass
      pkgs
      ;
  };
  themeChecks = import ./themes {
    inherit
      nitroLibs
      lib
      pass
      ;
  };
in
{
  nitroLibs-surface =
    assert missingLibNames == [ ];
    assert unexpectedLibNames == [ ];
    pass "nix-nitro-nitroLibs-surface";

  modulon-fixture =
    assert builtins.elem (toString ./modulon/modules/valid.nix) modulonImports;
    assert builtins.elem (toString ./modulon/extra-module.nix) modulonImports;
    assert !(builtins.elem (toString ./modulon/modules/skipped.nix) modulonImports);
    pass "nix-nitro-modulon-fixture";

  modulette-fixture =
    assert builtins.attrNames moduletteFixture == [ "alpha" ];
    assert moduletteFixture.alpha.value == "loaded";
    pass "nix-nitro-modulette-fixture";

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
    pass "nix-nitro-modulette-directory-fixture";

  guard-flake-input-fixture =
    assert missingInputGuard.has == false;
    assert missingInputGuard.input == null;
    pass "nix-nitro-guard-flake-input-fixture";

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
    pass "nix-nitro-dynamic-aliases-fixture";

  nix-options-to-md-fixture =
    assert nixOptionsToMdFixtureResult.hasHeader;
    assert nixOptionsToMdFixtureResult.hasEnableRow;
    assert nixOptionsToMdFixtureResult.hasPortRow;
    assert nixOptionsToMdFixtureResult.hasNestedRow;
    assert nixOptionsToMdFixtureResult.customNamespace;
    assert nixOptionsToMdFixtureResult.customExcludesNested;
    pass "nix-nitro-nix-options-to-md-fixture";
}
// rendererChecks
// themeChecks
