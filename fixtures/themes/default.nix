{
  fuelLibs,
  lib,
  pass,
}:

let
  enabledTheme = fuelLibs.themes.resolve {
    name = "nushell-inspired";
    enableColors = true;
  };
  disabledTheme = fuelLibs.themes.resolve {
    name = "nushell-inspired";
    enableColors = false;
  };
  amberTheme = fuelLibs.themes.resolve {
    name = "311amber";
    enableColors = true;
  };
  allThemesForced = builtins.deepSeq fuelLibs.themes.theme true;

  mkThemeFixture =
    name:
    let
      fixtureRoot = ./. + "/${name}";
    in
    import ../../libraries/themes/palette.nix {
      flakeRoot = fuelLibs.flakeRoot;
      inherit lib;
      palettesDirectory = fixtureRoot + "/palettes";
      themesDirectory = fixtureRoot + "/themes";
    };

  validThemeFixture = mkThemeFixture "valid";
  invalidThemeFixtures =
    map (name: builtins.tryEval (builtins.deepSeq (mkThemeFixture name).theme true))
      [
        "wrong-length"
        "missing-prefix"
        "invalid-digit"
        "invalid-override"
      ];
in
{
  themes-fixture =
    assert allThemesForced;
    assert disabledTheme.theme.bold_zero == "";
    assert disabledTheme.mode.reset == "";
    assert builtins.stringLength enabledTheme.theme.bold_zero > 0;
    assert builtins.stringLength enabledTheme.theme.zero > 0;
    # 311amber resolves the CRT palette rather than Tailwind orange.
    assert builtins.stringLength amberTheme.theme.bold_zero > 0;
    assert amberTheme.theme.bold_zero != enabledTheme.theme.bold_zero;
    pass "nix-fuel-themes-fixture";

  theme-validation-fixture =
    assert builtins.attrNames validThemeFixture.theme == [ "test" ];
    assert builtins.stringLength validThemeFixture.theme.test.bold_zero > 0;
    assert builtins.stringLength validThemeFixture.theme.test.zero > 0;
    assert builtins.all (result: result.success == false) invalidThemeFixtures;
    pass "nix-fuel-theme-validation-fixture";
}
