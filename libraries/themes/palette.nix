/*
  === Theme palette ===

  Source of truth: hex color definitions loaded from palette files in
  palettes/. Each theme declares which palette it uses and may override
  individual colors. Rendered as true-color escape codes. Auto-discovers
  theme files via Modulette.

  Architecture:
    1. Palette files (palettes/*.nix) define immutable hex color sets.
    2. Theme files (themes/*.nix) declare their palette and optional
       overrides, then map semantic slots to color names.
    3. palette.nix resolves each theme: loads its declared palette,
       applies overrides, builds the color attrset, and calls the
       theme's slots function.

  Color definitions start as hex values (#RRGGBB) and are converted
  to 24-bit true-color codes (\e[38;2;R;G;Bm) by the rendering layer.
  Bold variants use \e[1;38;2;R;G;Bm.
  Dimmed variants use computed reduced-brightness RGB rather than the
  faint SGR attribute (\e[2), which renders inconsistently across
  terminals when combined with 24-bit color — shifting hues
  (amber → brown, green → muddy).

  To add a new color: add the hex definition to one or more palette
  files in palettes/, then reference it in theme files as
  color.bold.<name>, color.dimmed.<name>, or color.<name>.

  To add a new palette: create a .nix file in palettes/ with a
  name → "#hex" attrset, then reference it from a theme file's
  palette field.
*/
{
  flakeRoot,
  lib,
  # Caller args → fixture source trees; public fuelLibs uses both defaults.
  palettesDirectory ? ./palettes,
  themesDirectory ? ./themes,
  ...
}:
let
  modulette = import (flakeRoot + "/libraries/auto-discover/modulette") { inherit lib; };

  # ----+ Configuration +----
  # Used when a theme does not declare the field.
  defaultPalette = "tailwind-inspired";
  defaultDimFactor = 0.55;

  # ----+ Palette discovery +----
  # Load all regular palette .nix files as name → validated hex attrsets.
  # Palettes are plain data files — no Modulette header validation needed.
  validateHexSet =
    context:
    lib.mapAttrs (
      name: value:
      if builtins.isString value && builtins.match "^#[0-9a-fA-F]{6}$" value != null then
        value
      else
        let
          actual = if builtins.isString value then builtins.toJSON value else builtins.typeOf value;
        in
        throw "Invalid ${context} color '${name}': expected #RRGGBB, got ${actual}"
    );

  palettes =
    let
      entryTypes = builtins.readDir palettesDirectory;
      entries = builtins.attrNames entryTypes;
      nixFiles = builtins.filter (
        name: entryTypes.${name} == "regular" && lib.hasSuffix ".nix" name
      ) entries;
      keyFromName = name: builtins.substring 0 (builtins.stringLength name - 4) name;
    in
    builtins.listToAttrs (
      map (
        name:
        let
          paletteName = keyFromName name;
        in
        lib.nameValuePair paletteName (
          validateHexSet "palette '${paletteName}'" (import (palettesDirectory + "/${name}"))
        )
      ) nixFiles
    );

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
  #
  # Dimmed colors use computed reduced-brightness RGB instead of the
  # faint SGR attribute (\e[2). The faint attribute renders
  # inconsistently across terminals when combined with 24-bit color —
  # shifting hues (amber → brown, green → muddy). Computing dimmed as
  # a lower-brightness true-color code produces predictable results.
  fg = rgb: "\\e[38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";
  boldFg = rgb: "\\e[1;38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";

  # ----+ Build color attrset from hex definitions +----
  # Given a hex attrset (name → "#RRGGBB") and a dim factor, produce
  # the color attrset with regular, bold, and dimmed variants.
  # Palettes are immutable — themes override at the hex level before
  # this function is called.
  makeColor =
    {
      hex,
      dimFactor ? defaultDimFactor,
    }:
    let
      dimmedRgb = rgb: {
        r = builtins.floor (builtins.mul rgb.r dimFactor);
        g = builtins.floor (builtins.mul rgb.g dimFactor);
        b = builtins.floor (builtins.mul rgb.b dimFactor);
      };
    in
    (lib.mapAttrs (_: h: fg (fromHex h)) hex)
    // {
      bold = lib.mapAttrs (_: h: boldFg (fromHex h)) hex;
      dimmed = lib.mapAttrs (_: h: fg (dimmedRgb (fromHex h))) hex;
    };

  # ----+ Text attributes +----
  # Mode codes are theme-independent — reset, italic, etc.
  mode = {
    italic = "\\e[3m";
    reset = "\\e[0m";
  };

  # ----+ Auto-discover and resolve themes +----
  # Theme files declare their palette and optional overrides, then
  # provide a slots function that maps color names to semantic slots.
  # palette.nix resolves each theme by: loading its declared palette,
  # applying overrides, building the color attrset, and calling slots.
  rawThemes = modulette.discoverModules {
    mode = "flat";
    directory = themesDirectory;
    headerPrefix = "# Theme module.";
    args = { };
  };

  themes = lib.mapAttrs (
    name: rawTheme:
    let
      paletteName = rawTheme.palette or defaultPalette;
      basePalette =
        palettes.${paletteName}
          or (throw "Unknown palette '${paletteName}' for theme '${name}'. Available palettes: ${lib.concatStringsSep ", " (builtins.attrNames palettes)}");
      overrides = validateHexSet "theme '${name}' override" (rawTheme.overrides or { });
      hex = basePalette // overrides;
      color = builtins.deepSeq hex (makeColor {
        inherit hex;
        dimFactor = rawTheme.dimFactor or defaultDimFactor;
      });
    in
    rawTheme.slots { inherit color; }
  ) rawThemes;
in
rec {
  theme = builtins.deepSeq palettes themes;
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
