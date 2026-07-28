# Theme option — loaded by Modulon, declares the per-host theme selection.
# The actual theme data is rendered by resolver.nix (imported by mkLibrary).
#
# enableColors controls whether resolved escape codes produce real terminal
# colors (true) or empty strings (false). When false, every color slot and
# mode code resolves to "" — same printf structure, zero visual modifiers.
# This produces plain-text output suitable for minimal terminals, CI, or
# accessibility preferences.
#
# When null (the default), colors are enabled when at least one shell program
# is active for the host.
{ lib, ... }:
{
  options.myOptions.hm.data.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "nushell-inspired";
      description = "Color theme name (must match a key in libThemes.theme)";
    };
    enableColors = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Whether to emit terminal color codes. When null (default), colors are
        enabled when at least one shell program is active for the host. Set to
        false to strip all color codes from shell output.
      '';
    };
  };
}
