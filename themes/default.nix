# Theme option — loaded by Modulon, declares the per-host theme selection.
# The actual theme data lives in palette.nix (pure data, imported by mkLibrary).
{ lib, ... }:
{
  options.myOptions.hm.data.theme.name = lib.mkOption {
    type = lib.types.str;
    default = "nushell-inspired";
    description = "Color theme name (must match a key in libThemes.theme)";
  };
}
