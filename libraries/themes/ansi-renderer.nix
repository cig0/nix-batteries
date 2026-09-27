/*
  ANSI presentation for validated theme data.

  normalizer.nix guarantees the input shape. This module renders every
  declared role into its three presentations and publishes the
  theme-independent terminal mode codes.

  Presentations are grouped by presentation name. `base`, `bold`, and `dim`
  each hold one entry per declared role, so a consumer reads
  `theme.bold.context` instead of a prefixed flat key.
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

  /*
    Presentation is derived from the role's color, never from its name. A theme
    that adds an optional role therefore gains its three presentations without
    any edit here, and no authored name can select a different presentation.

    dim scales the channels instead of emitting SGR 2, so mode.dim remains the
    distinct terminal dim mode.
  */
  renderPresentation =
    renderRgb: lib.mapAttrs (_roleName: hexColor: renderRgb (colorOperations.hexColorToRgb hexColor));
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
    {
      boldFactor,
      dimFactor,
      roles,
      ...
    }:
    {
      base = renderPresentation renderForegroundColor roles;
      bold = renderPresentation (
        rgb: renderBoldForegroundColor (colorOperations.scaleRgb boldFactor rgb)
      ) roles;
      dim = renderPresentation (
        rgb: renderForegroundColor (colorOperations.scaleRgb dimFactor rgb)
      ) roles;
    };
}
