/*
  === Theme palette ===

  Pure data: defines shared colors and modes, auto-discovers theme files
  via Modulette. The single source of truth for ANSI escape codes consumed
  by all shell modules through libThemes.

  Theme files in the themes/ subdirectory are discovered automatically —
  drop a .nix file with the "# ANSI theme module." header and it becomes
  available.

  Colors are referenced by name here; theme modules map numbered semantic
  slots (bold_zero, bold_one, …) to these names.  Consuming code uses only
  the numbered slots so that switching themes requires no other changes.
*/
{ lib, flakeRoot, ... }:
let
  modulette = import (flakeRoot + "/lib/modulette") { inherit lib; };

  # ----+ Shared color palette +----
  # Available to all themes via the { color }: parameter.
  # Add new shared colors here; theme-specific colors stay local.
  color = {
    bold = {
      blue = "\\e[1;34m";
      cyan = "\\e[1;36m";
      green = "\\e[1;32m";
      magenta = "\\e[1;35m";
      red = "\\e[1;31m";
      yellow = "\\e[1;33m";
      white = "\\e[1;97m";
    };
    dimmed = {
      green = "\\e[2;32m";
      white = "\\e[2;37m";
    };
    blue = "\\e[34m";
    cyan = "\\e[36m";
    green = "\\e[32m";
    magenta = "\\e[35m";
    red = "\\e[31m";
    yellow = "\\e[33m";
    white = "\\e[97m";
  };

  # ----+ Text attributes +----
  # Mode codes are theme-independent — reset, italic, etc.
  mode = {
    italic = "\\e[3m";
    reset = "\\e[0m";
  };

  # ----+ Auto-discover themes +----
  themes = modulette.discoverModules {
    directory = ./themes;
    headerPrefix = "# ANSI theme module.";
    args = { inherit color; };
  };
in
rec {
  theme = themes;
  inherit mode;

  select = name: {
    theme =
      themes.${name}
        or (throw "Unknown theme '${name}'. Available themes: ${lib.concatStringsSep ", " (builtins.attrNames themes)}");
    inherit mode;
  };

  withoutAnsi =
    libThemes:
    libThemes
    // {
      theme = lib.mapAttrs (_: _: "") libThemes.theme;
      mode = lib.mapAttrs (_: _: "") libThemes.mode;
    };

  resolve =
    {
      name,
      enableAnsi ? true,
    }:
    let
      selected = select name;
    in
    if enableAnsi then selected else withoutAnsi selected;
}
