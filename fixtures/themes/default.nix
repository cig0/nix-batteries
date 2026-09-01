{
  nitroLibs,
  lib,
  pass,
}:

let
  enabledTheme = nitroLibs.themes.resolve {
    name = "nushell-inspired";
    enableColors = true;
  };
  disabledTheme = nitroLibs.themes.resolve {
    name = "nushell-inspired";
    enableColors = false;
  };
  amberTheme = nitroLibs.themes.resolve {
    name = "311amber";
    enableColors = true;
  };
  allThemesForced = builtins.deepSeq [ nitroLibs.themes.colors nitroLibs.themes.theme ] true;
  requiredSlots = [
    "zero"
    "one"
    "two"
    "three"
    "four"
    "five"
    "six"
    "seven"
    "bold_zero"
    "bold_one"
    "bold_two"
    "bold_three"
    "bold_four"
    "bold_five"
    "bold_six"
    "bold_seven"
    "dimmed_zero"
    "dimmed_one"
  ];
  allThemesComplete = builtins.all (
    theme:
    builtins.all (
      slot: builtins.hasAttr slot theme && builtins.stringLength theme.${slot} > 0
    ) requiredSlots
  ) (builtins.attrValues nitroLibs.themes.theme);

  mkThemeFixture =
    name:
    let
      fixtureRoot = ./. + "/${name}";
    in
    import ../../libraries/themes/resolver.nix {
      flakeRoot = nitroLibs.flakeRoot;
      inherit lib;
      themesDirectory = fixtureRoot + "/themes";
      themeModuleSourceDirectory = "fixtures/themes/${name}/themes";
    };

  validThemeFixture = mkThemeFixture "valid";
  invalidThemeFixtures =
    map (name: builtins.tryEval (builtins.deepSeq (mkThemeFixture name).theme true))
      [
        "wrong-length"
        "missing-prefix"
        "invalid-digit"
        "invalid-factor"
        "invalid-selection"
        "missing-slot"
      ];
in
{
  themes-fixture =
    assert allThemesForced;
    assert allThemesComplete;
    assert disabledTheme.theme.bold_zero == "";
    assert disabledTheme.theme.seven == "";
    assert disabledTheme.colors == null;
    assert builtins.all (value: value == "") (builtins.attrValues disabledTheme.mode);
    assert builtins.stringLength enabledTheme.theme.bold_zero > 0;
    assert builtins.stringLength enabledTheme.theme.zero > 0;
    assert enabledTheme.mode.blink == "\\e[5m";
    assert enabledTheme.mode.dim == "\\e[2m";
    assert enabledTheme.mode.italic == "\\e[3m";
    assert enabledTheme.mode.reset == "\\e[0m";
    assert enabledTheme.mode.reverse == "\\e[7m";
    assert enabledTheme.mode.underline == "\\e[4m";
    assert enabledTheme.colors.zero == "#00cd00";
    assert !(enabledTheme.colors ? selection);
    # The factor refactor preserves the existing 311amber output.
    assert amberTheme.theme.bold_zero == "\\e[1;38;2;255;179;67m";
    assert amberTheme.theme.dimmed_zero == "\\e[38;2;140;98;36m";
    assert amberTheme.theme.bold_zero != enabledTheme.theme.bold_zero;
    assert amberTheme.colors.zero == "#ffb343";
    assert amberTheme.colors.selection.background == "#ffff00";
    assert amberTheme.colors.selection.foreground == "#000000";
    assert
      nitroLibs.themes.themeMetadata."311amber" == {
        provider = "nix-nitro";
        source = "libraries/themes/themes/311amber.nix";
      };
    pass "nix-nitro-themes-fixture";

  theme-validation-fixture =
    assert builtins.attrNames validThemeFixture.theme == [ "test" ];
    assert validThemeFixture.colors.test.zero == "#204060";
    assert !(validThemeFixture.colors.test ? selection);
    assert validThemeFixture.theme.test.zero == "\\e[38;2;32;64;96m";
    assert validThemeFixture.theme.test.bold_zero == "\\e[1;38;2;48;96;144m";
    assert validThemeFixture.theme.test.bold_five == "\\e[1;38;2;255;255;255m";
    assert validThemeFixture.theme.test.dimmed_zero == "\\e[38;2;16;32;48m";
    assert
      validThemeFixture.themeMetadata.test == {
        provider = "nix-nitro";
        source = "fixtures/themes/valid/themes/test.nix";
      };
    assert builtins.all (result: result.success == false) invalidThemeFixtures;
    pass "nix-nitro-theme-validation-fixture";
}
