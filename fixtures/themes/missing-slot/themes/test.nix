# Theme module. Fixture theme.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  slots = builtins.removeAttrs validTheme.slots [ "seven" ];
}
