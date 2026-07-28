/*
  === Theme resolver ===

  Each theme owns its semantic slot colors as #RRGGBB values. Slot names
  declare rendering intent:

    zero         regular true-color foreground
    bold_zero    bold true-color foreground scaled by boldFactor
    dimmed_zero  regular true-color foreground scaled by dimFactor

  Theme files are auto-discovered via Modulette. The resolver validates each
  theme, applies its factors, and exports the rendered escape-code strings.
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
    italic = "\\e[3m";
    reset = "\\e[0m";
  };

  rawThemes = modulette.discoverModules {
    mode = "flat";
    directory = themesDirectory;
    headerPrefix = "# Theme module.";
    args = { };
  };

  themes = lib.mapAttrs (
    name: rawTheme:
    let
      boldFactor = validateFactor "theme '${name}' boldFactor" (rawTheme.boldFactor or defaultBoldFactor);
      dimFactor = validateFactor "theme '${name}' dimFactor" (rawTheme.dimFactor or defaultDimFactor);
      slots = validateHexSet "theme '${name}'" (validateRequiredSlots name rawTheme.slots);
    in
    builtins.deepSeq [ boldFactor dimFactor slots ] (
      lib.mapAttrs (
        slotName: hex:
        renderSlot {
          inherit
            boldFactor
            dimFactor
            hex
            ;
          name = slotName;
        }
      ) slots
    )
  ) rawThemes;
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
