/*
  Theme-library fixture boundary.

  The public batteriesLib.themes result and fixture-only theme directories
  enter here. This file verifies raw role colors, generated ANSI
  presentations, provenance, and rejection of invalid source contracts.
*/
{
  batteriesLib, # fixtures/default.nix → batteriesLib
  lib, # fixtures/default.nix → nixpkgs.lib
  pass, # fixtures/default.nix → fixture pass command
}:

let
  # Stated explicitly so a silent contract change fails here instead of
  # comparing the library against itself.
  requiredRoles = [
    "accent"
    "emphasis"
    "option"
    "success"
    "value"
    "warning"
    "error"
    "notice"
    "context"
  ];
  presentationsOf = roleName: [
    roleName
    "bold_${roleName}"
    "dim_${roleName}"
  ];
  sortNames = builtins.sort (left: right: left < right);
  requiredPresentations = sortNames (lib.concatMap presentationsOf requiredRoles);

  enabledTheme = batteriesLib.themes.resolve {
    name = "nushell-inspired";
    enableColors = true;
  };
  disabledTheme = batteriesLib.themes.resolve {
    name = "nushell-inspired";
    enableColors = false;
  };
  amberTheme = batteriesLib.themes.resolve {
    name = "311amber";
    enableColors = true;
  };
  unknownThemeResult = builtins.tryEval (
    builtins.deepSeq (batteriesLib.themes.resolve {
      name = "no-such-theme";
      enableColors = true;
    }) true
  );

  allThemesForced = builtins.deepSeq [
    batteriesLib.themes.colors
    batteriesLib.themes.theme
  ] true;

  # Bundled themes declare exactly the required roles, so their generated key
  # set is exactly three presentations per required role.
  bundledPresentationsComplete = builtins.all (
    renderedTheme: builtins.attrNames renderedTheme == requiredPresentations
  ) (builtins.attrValues batteriesLib.themes.theme);
  bundledPresentationsPrintable = builtins.all (
    renderedTheme:
    builtins.all (escapeCode: lib.hasPrefix "\\e[" escapeCode) (builtins.attrValues renderedTheme)
  ) (builtins.attrValues batteriesLib.themes.theme);

  # Raw colors publish authored role hexes only; presentations live in theme.
  bundledColorsAreRoles = builtins.all (
    themeColors:
    builtins.attrNames (builtins.removeAttrs themeColors [ "selection" ]) == sortNames requiredRoles
  ) (builtins.attrValues batteriesLib.themes.colors);
  themesWithSelection = builtins.filter (
    themeName: batteriesLib.themes.colors.${themeName} ? selection
  ) (builtins.attrNames batteriesLib.themes.colors);

  # Bundled palette assertion only: third-party themes may reuse one hex.
  bundledSuccessDiffersFromError = builtins.all (
    themeColors: themeColors.success != themeColors.error
  ) (builtins.attrValues batteriesLib.themes.colors);

  mkThemeFixture =
    name:
    let
      fixtureRoot = ./. + "/${name}";
    in
    import ../../libraries/themes/resolver.nix {
      flakeRoot = batteriesLib.flakeRoot;
      inherit lib;
      themesDirectory = fixtureRoot + "/themes";
      themeModuleSourceDirectory = "fixtures/themes/${name}/themes";
    };

  validThemeFixture = mkThemeFixture "valid";
  zeroFactorFixture = mkThemeFixture "zero-factor";
  defaultFactorsFixture = mkThemeFixture "default-factors";
  invalidThemeFixtures =
    map (name: builtins.tryEval (builtins.deepSeq (mkThemeFixture name).theme true))
      [
        "wrong-length"
        "missing-prefix"
        "invalid-digit"
        "invalid-factor"
        "invalid-selection"
        "missing-role"
        "ordinal-slots"
        "roles-not-attrs"
        "reserved-selection"
        "reserved-bold"
        "reserved-dim"
      ];
in
{
  themes-fixture =
    assert allThemesForced;
    assert bundledPresentationsComplete;
    assert bundledPresentationsPrintable;
    assert bundledColorsAreRoles;
    assert bundledSuccessDiffersFromError;
    assert themesWithSelection == [ "311amber" ];
    assert disabledTheme.theme.bold_accent == "";
    assert disabledTheme.theme.context == "";
    assert builtins.all (value: value == "") (builtins.attrValues disabledTheme.theme);
    assert builtins.attrNames disabledTheme.theme == requiredPresentations;
    assert disabledTheme.colors == null;
    assert builtins.all (value: value == "") (builtins.attrValues disabledTheme.mode);
    assert unknownThemeResult.success == false;
    assert builtins.stringLength enabledTheme.theme.bold_accent > 0;
    assert builtins.stringLength enabledTheme.theme.accent > 0;
    assert enabledTheme.mode.blink == "\\e[5m";
    assert enabledTheme.mode.dim == "\\e[2m";
    assert enabledTheme.mode.italic == "\\e[3m";
    assert enabledTheme.mode.reset == "\\e[0m";
    assert enabledTheme.mode.reverse == "\\e[7m";
    assert enabledTheme.mode.underline == "\\e[4m";
    assert enabledTheme.colors.accent == "#00cd00";
    assert !(enabledTheme.colors ? selection);
    assert !(enabledTheme.colors ? bold_accent);
    assert !(enabledTheme.colors ? dim_accent);
    # The role refactor preserves the existing 311amber rendering.
    assert amberTheme.theme.accent == "\\e[38;2;255;179;67m";
    assert amberTheme.theme.bold_accent == "\\e[1;38;2;255;179;67m";
    assert amberTheme.theme.dim_accent == "\\e[38;2;140;98;36m";
    assert amberTheme.theme.bold_accent != enabledTheme.theme.bold_accent;
    assert amberTheme.colors.accent == "#ffb343";
    assert amberTheme.colors.selection.background == "#ffff00";
    assert amberTheme.colors.selection.foreground == "#000000";
    assert amberTheme.colors.success == "#00ff7f";
    assert amberTheme.colors.error == "#ff0000";
    assert
      batteriesLib.themes.themeMetadata."311amber" == {
        provider = "nix-batteries";
        source = "libraries/themes/themes/311amber.nix";
      };
    pass "nix-batteries-themes-fixture";

  theme-validation-fixture =
    assert builtins.attrNames validThemeFixture.theme == [ "test" ];
    assert validThemeFixture.colors.test.accent == "#204060";
    assert !(validThemeFixture.colors.test ? selection);
    assert validThemeFixture.theme.test.accent == "\\e[38;2;32;64;96m";
    assert validThemeFixture.theme.test.bold_accent == "\\e[1;38;2;48;96;144m";
    assert validThemeFixture.theme.test.dim_accent == "\\e[38;2;16;32;48m";
    # boldFactor 1.5 clamps every channel of a light role at 255.
    assert validThemeFixture.theme.test.bold_warning == "\\e[1;38;2;255;255;255m";
    # An optional extra role gains its three presentations with no library edit.
    assert validThemeFixture.colors.test.spotlight == "#123456";
    assert validThemeFixture.theme.test.spotlight == "\\e[38;2;18;52;86m";
    assert validThemeFixture.theme.test.bold_spotlight == "\\e[1;38;2;27;78;129m";
    assert validThemeFixture.theme.test.dim_spotlight == "\\e[38;2;9;26;43m";
    assert
      builtins.attrNames validThemeFixture.theme.test
      == sortNames (requiredPresentations ++ presentationsOf "spotlight");
    assert
      validThemeFixture.themeMetadata.test == {
        provider = "nix-batteries";
        source = "fixtures/themes/valid/themes/test.nix";
      };
    # Zero factors scale every channel to zero; plain output is unaffected.
    assert zeroFactorFixture.theme.test.accent == "\\e[38;2;32;64;96m";
    assert zeroFactorFixture.theme.test.bold_accent == "\\e[1;38;2;0;0;0m";
    assert zeroFactorFixture.theme.test.dim_accent == "\\e[38;2;0;0;0m";
    # Omitted factors fall back to contract defaults 1.0 and 0.55.
    assert defaultFactorsFixture.theme.test.bold_accent == "\\e[1;38;2;32;64;96m";
    assert defaultFactorsFixture.theme.test.dim_accent == "\\e[38;2;17;35;52m";
    assert builtins.all (result: result.success == false) invalidThemeFixtures;
    pass "nix-batteries-theme-validation-fixture";
}
