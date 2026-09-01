/*
  Public theme resolution pipeline.

  discovery.nix → normalizer.nix → raw colors and ANSI presentation

  This module coordinates those boundaries and exposes the stable public API.
  Theme source data, validation rules, color arithmetic, ANSI rendering, and
  provenance construction remain owned by their adjacent atomic modules.
*/
{
  flakeRoot,
  lib,
  # Supports focused fixture source trees without changing discovery behavior.
  themesDirectory ? ./themes,
  # Logical provider path published by provenance.nix; fixtures override it.
  themeModuleSourceDirectory ? "libraries/themes/themes",
  ...
}:
let
  themeContract = import ./contract.nix;
  themeAssertions = import ./assertions.nix {
    inherit lib themeContract;
  };
  normalizeTheme = import ./normalizer.nix {
    inherit themeAssertions themeContract;
  };
  colorOperations = import ./colors.nix;
  ansiRenderer = import ./ansi-renderer.nix {
    inherit colorOperations lib;
  };

  discoveredThemes = import ./discovery.nix {
    inherit flakeRoot lib themesDirectory;
  };

  normalizedThemes = lib.mapAttrs normalizeTheme discoveredThemes;
  renderedThemes = lib.mapAttrs (_themeName: ansiRenderer.renderTheme) normalizedThemes;

  # Raw colors serve tools such as fzf that accept #RRGGBB but not ANSI codes.
  rawThemeColors = lib.mapAttrs (
    _themeName: normalizedTheme:
    normalizedTheme.slots
    // lib.optionalAttrs (normalizedTheme.selection != null) {
      inherit (normalizedTheme) selection;
    }
  ) normalizedThemes;

  themeMetadata = import ./provenance.nix {
    inherit discoveredThemes lib themeModuleSourceDirectory;
  };
in
rec {
  colors = rawThemeColors;
  theme = renderedThemes;
  mode = ansiRenderer.terminalModes;
  inherit themeMetadata;

  select =
    themeName:
    if builtins.hasAttr themeName renderedThemes then
      {
        colors = rawThemeColors.${themeName};
        theme = renderedThemes.${themeName};
        inherit mode;
      }
    else
      throw "Unknown theme '${themeName}'. Available themes: ${lib.concatStringsSep ", " (builtins.attrNames renderedThemes)}";

  withoutColors =
    selectedTheme:
    selectedTheme
    // {
      # Raw colors cannot represent disabled styling; null makes that absence explicit.
      colors = null;
      theme = lib.mapAttrsRecursive (_attributePath: _escapeCode: "") selectedTheme.theme;
      mode = lib.mapAttrs (_modeName: _escapeCode: "") selectedTheme.mode;
    };

  resolve =
    {
      name,
      enableColors ? true,
    }:
    let
      selectedTheme = select name;
    in
    if enableColors then selectedTheme else withoutColors selectedTheme;
}
