/*
  ANSI presentation for validated theme data.

  normalizer.nix guarantees the input shape. This module renders every
  declared role into its three presentations and publishes the
  theme-independent terminal mode codes.
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
  renderRolePresentations =
    {
      boldFactor,
      dimFactor,
      hexColor,
      roleName,
    }:
    let
      sourceRgb = colorOperations.hexColorToRgb hexColor;
    in
    {
      "${roleName}" = renderForegroundColor sourceRgb;
      "bold_${roleName}" = renderBoldForegroundColor (colorOperations.scaleRgb boldFactor sourceRgb);
      "dim_${roleName}" = renderForegroundColor (colorOperations.scaleRgb dimFactor sourceRgb);
    };
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
    lib.concatMapAttrs (
      roleName: hexColor:
      renderRolePresentations {
        inherit (normalizedTheme) boldFactor dimFactor;
        inherit hexColor roleName;
      }
    ) normalizedTheme.roles;
}
