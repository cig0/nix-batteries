/*
  === Theme resolver ===

  Each theme owns its semantic slot colors as #RRGGBB values. Slot names
  declare rendering intent:

    zero         regular true-color foreground
    bold_zero    bold true-color foreground scaled by boldFactor
    dimmed_zero  regular true-color foreground scaled by dimFactor

  Theme files are auto-discovered via Modulette. The resolver validates each
  theme, preserves its raw colors for consumers that cannot use ANSI escape
  codes, and renders the numbered slots as escape-code strings.
*/
{
  flakeRoot,
  lib,
  # Caller arg supports focused fixture source trees.
  themesDirectory ? ./themes,
  ...
}:
let
  modulette = import (flakeRoot + "/libraries/auto-discover/modulette") { inherit lib; };

  defaultBoldFactor = 1.0;
  defaultDimFactor = 0.55;

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
        throw "Invalid ${context} slot '${name}': expected #RRGGBB, got ${actual}"
    );

  validateFactor =
    context: value:
    if (builtins.isInt value || builtins.isFloat value) && value >= 0 then
      value
    else
      let
        actual =
          if builtins.isInt value || builtins.isFloat value then
            toString value
          else if builtins.isString value then
            builtins.toJSON value
          else
            builtins.typeOf value;
      in
      throw "Invalid ${context}: expected a non-negative number, got ${actual}";

  validateRequiredSlots =
    name: slots:
    let
      missing = builtins.filter (slot: !(builtins.hasAttr slot slots)) requiredSlots;
    in
    if missing == [ ] then
      slots
    else
      throw "Theme '${name}' is missing required slots: ${lib.concatStringsSep ", " missing}";

  /*
    Selection colors are an optional, narrowly scoped theme contract for
    interactive menus. Both roles are required together so consumers never
    have to infer a foreground or background from unrelated numbered slots.
  */
  validateSelection =
    themeName: selection:
    if selection == null then
      null
    else if !builtins.isAttrs selection then
      throw "Invalid theme '${themeName}' selection: expected an attribute set"
    else
      let
        requiredFields = [
          "background"
          "foreground"
        ];
        selectionFields = builtins.attrNames selection;
        missingFields = builtins.filter (field: !(builtins.hasAttr field selection)) requiredFields;
        unexpectedFields = builtins.filter (field: !(builtins.elem field requiredFields)) selectionFields;
      in
      if missingFields != [ ] then
        throw "Theme '${themeName}' selection is missing fields: ${lib.concatStringsSep ", " missingFields}"
      else if unexpectedFields != [ ] then
        throw "Theme '${themeName}' selection has unsupported fields: ${lib.concatStringsSep ", " unexpectedFields}"
      else
        validateHexSet "theme '${themeName}' selection" selection;

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
    value:
    let
      length = builtins.stringLength value;
      go =
        position: accumulator:
        if position >= length then
          accumulator
        else
          go (position + 1) (accumulator * 16 + hexDigitToInt (builtins.substring position 1 value));
    in
    go 0 0;

  fromHex = hex: {
    r = hexToInt (builtins.substring 1 2 hex);
    g = hexToInt (builtins.substring 3 2 hex);
    b = hexToInt (builtins.substring 5 2 hex);
  };

  scaleRgb =
    factor: rgb:
    let
      scaleChannel =
        channel:
        let
          scaled = builtins.floor (builtins.mul channel factor);
        in
        if scaled > 255 then 255 else scaled;
    in
    {
      r = scaleChannel rgb.r;
      g = scaleChannel rgb.g;
      b = scaleChannel rgb.b;
    };

  fg = rgb: "\\e[38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";
  boldFg = rgb: "\\e[1;38;2;${toString rgb.r};${toString rgb.g};${toString rgb.b}m";

  renderSlot =
    {
      boldFactor,
      dimFactor,
      hex,
      name,
    }:
    let
      rgb = fromHex hex;
    in
    if lib.hasPrefix "bold_" name then
      boldFg (scaleRgb boldFactor rgb)
    else if lib.hasPrefix "dimmed_" name then
      fg (scaleRgb dimFactor rgb)
    else
      fg rgb;

  mode = {
    blink = "\\e[5m";
    dim = "\\e[2m";
    italic = "\\e[3m";
    reset = "\\e[0m";
    reverse = "\\e[7m";
    underline = "\\e[4m";
  };

  rawThemes = modulette.discoverModules {
    mode = "flat";
    directory = themesDirectory;
    headerPrefix = "# Theme module.";
    args = { };
  };

  /*
    Validate source data once, then derive both public representations from the
    same normalized themes. This keeps raw data separate from ANSI rendering.
  */
  normalizedThemes = lib.mapAttrs (
    name: rawTheme:
    let
      boldFactor = validateFactor "theme '${name}' boldFactor" (rawTheme.boldFactor or defaultBoldFactor);
      dimFactor = validateFactor "theme '${name}' dimFactor" (rawTheme.dimFactor or defaultDimFactor);
      slots = validateHexSet "theme '${name}'" (validateRequiredSlots name rawTheme.slots);
      selection = validateSelection name (rawTheme.selection or null);
    in
    builtins.deepSeq [ boldFactor dimFactor slots selection ] {
      inherit
        boldFactor
        dimFactor
        selection
        slots
        ;
    }
  ) rawThemes;

  themes = lib.mapAttrs (
    _name: normalizedTheme:
    lib.mapAttrs (
      slotName: hex:
      renderSlot {
        inherit (normalizedTheme) boldFactor dimFactor;
        inherit hex;
        name = slotName;
      }
    ) normalizedTheme.slots
  ) normalizedThemes;

  # Raw colors serve tools such as fzf that accept #RRGGBB but not ANSI codes.
  colors = lib.mapAttrs (
    _name: normalizedTheme:
    normalizedTheme.slots
    // lib.optionalAttrs (normalizedTheme.selection != null) {
      inherit (normalizedTheme) selection;
    }
  ) normalizedThemes;
in
rec {
  inherit colors;
  theme = themes;
  inherit mode;

  select =
    name:
    if builtins.hasAttr name themes then
      {
        colors = colors.${name};
        theme = themes.${name};
        inherit mode;
      }
    else
      throw "Unknown theme '${name}'. Available themes: ${lib.concatStringsSep ", " (builtins.attrNames themes)}";

  withoutColors =
    libThemes:
    libThemes
    // {
      # Raw colors cannot represent disabled styling; null makes that absence explicit.
      colors = null;
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
