/*
  ANSI presentation for validated theme data.

  normalizer.nix guarantees the input shape. This module converts each raw
  color into its terminal escape sequence according to the slot-name contract
  and publishes the theme-independent terminal mode codes.
*/
{
  colorOperations, # resolver.nix → colors.nix
  lib, # resolver.nix → nixpkgs.lib
}:
let
  renderForegroundColor =
    rgb: "\\e[38;2;${toString rgb.red};${toString rgb.green};${toString rgb.blue}m";

  renderBoldForegroundColor =
    rgb: "\\e[1;38;2;${toString rgb.red};${toString rgb.green};${toString rgb.blue}m";

  renderThemeSlot =
    {
      boldFactor,
      dimFactor,
      hexColor,
      slotName,
    }:
    let
      sourceRgb = colorOperations.hexColorToRgb hexColor;
    in
    if lib.hasPrefix "bold_" slotName then
      renderBoldForegroundColor (colorOperations.scaleRgb boldFactor sourceRgb)
    else if lib.hasPrefix "dimmed_" slotName then
      renderForegroundColor (colorOperations.scaleRgb dimFactor sourceRgb)
    else
      renderForegroundColor sourceRgb;
in
{
  terminalModes = {
    blink = "\\e[5m";
    dim = "\\e[2m";
    italic = "\\e[3m";
    reset = "\\e[0m";
    reverse = "\\e[7m";
    underline = "\\e[4m";
  };

  renderTheme =
    normalizedTheme:
    lib.mapAttrs (
      slotName: hexColor:
      renderThemeSlot {
        inherit (normalizedTheme) boldFactor dimFactor;
        inherit hexColor slotName;
      }
    ) normalizedTheme.slots;
}
