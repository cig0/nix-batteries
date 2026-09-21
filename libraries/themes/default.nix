/*
  Theme option module — declares the per-host theme selection.

  Consumed as a Nix module through `batteriesLib.themeOptionModule`, which
  consumers add to `imports` or to Modulon's `extraModules`. resolver.nix owns
  theme discovery, validation, and rendering; this file only declares the
  `name` and `enableColors` options that select one resolved theme.

  enableColors controls whether resolved escape codes produce real terminal
  colors (true) or empty strings (false). When false, every color slot and
  mode code resolves to "" — same printf structure, zero visual modifiers.
  This produces plain-text output suitable for minimal terminals, CI, or
  accessibility preferences.

  When null (the default), the consuming configuration decides whether active
  shells should enable colors.
*/
{ lib, ... }:
{
  options.myOptions.hm.data.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "nushell-inspired";
      description = "Color theme name; must match a key in batteriesLib.themes.theme";
    };
    enableColors = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to emit terminal color codes. When null (default), the
        consuming configuration decides whether active shells enable colors.
        Set to false to strip all color codes from shell output.
      '';
    };
  };
}
