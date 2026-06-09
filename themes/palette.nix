/*
  === Theme palette ===

  Source of truth: hex color definitions, rendered as true-color
  escape codes. Auto-discovers theme files via Modulette.

  Color definitions start as hex values (#RRGGBB) and are converted
  to 24-bit true-color codes (\e[38;2;R;G;Bm) by the rendering layer.
  Bold and dimmed variants are derived automatically — add a hex entry
  and all three variants become available.

  Theme modules map numbered semantic slots (bold_zero, bold_one, …)
  to these palette names. Consuming code uses only the numbered slots
  so that switching themes requires no other changes.

  To add a new color: add the hex definition to the `hex` attrset
  below, then reference it in theme files as color.bold.<name>,
  color.dimmed.<name>, or color.<name>.
*/
{ lib, flakeRoot, ... }:
let
  modulette = import (flakeRoot + "/modulette") { inherit lib; };

  # ----+ Hex color definitions (source of truth) +----
  # New colors should be added here to make them available to all themes.
  # Each entry generates bold, dimmed, and regular foreground variants.
  hex = {
    blue = "#3b82f6";
    cyan = "#06b6d4";
    green = "#22c55e";
    grey = "#6b7280";
    magenta = "#d946ef";
    red = "#ef4444";
    white = "#f8fafc";
    yellow = "#f59e0b";
  };

  # ----+ Hex → RGB conversion +----
  hexDigitToInt =
    d:
    {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      a = 10;
      b = 11;
      c = 12;
      d = 13;
      e = 14;
      f = 15;
      A = 10;
      B = 11;
      C = 12;
      D = 13;
      E = 14;
      F = 15;
    }
    .${d};

  hexToInt =
    s:
    let
      len = builtins.stringLength s;
      go =
        pos: acc:
        if pos >= len then acc else go (pos + 1) (acc * 16 + hexDigitToInt (builtins.substring pos 1 s));
    in
    go 0 0;

  fromHex = h: {
    r = hexToInt (builtins.substring 1 2 h);
    g = hexToInt (builtins.substring 3 2 h);
    b = hexToInt (builtins.substring 5 2 h);
  };

  # ----+ True-color rendering +----
  # \e[38;2;R;G;Bm       — 24-bit foreground
  # \e[1;38;2;R;G;Bm     — bold + 24-bit foreground
  # \e[2;38;2;R;G;Bm     — dimmed + 24-bit foreground
  fg = rgb: "\\e[38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";
  boldFg = rgb: "\\e[1;38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";
  dimmedFg = rgb: "\\e[2;38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";

  # ----+ Derived color palette +----
  # Bold, dimmed, and regular variants generated from hex definitions.
  # Themes consume color.bold.green, color.dimmed.green, color.green, etc.
  color = (lib.mapAttrs (_: h: fg (fromHex h)) hex) // {
    bold = lib.mapAttrs (_: h: boldFg (fromHex h)) hex;
    dimmed = lib.mapAttrs (_: h: dimmedFg (fromHex h)) hex;
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
    headerPrefix = "# Theme module.";
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

  withoutColors =
    libThemes:
    libThemes
    // {
      theme = lib.mapAttrsRecursive (_: _: "") libThemes.theme;
      mode = lib.mapAttrs (_: _: "") libThemes.mode;
    };

  resolve =
    {
      name,
      enableColors ? true,
    }:
    let
      selected = select name;
    in
    if enableColors then selected else withoutColors selected;
}
