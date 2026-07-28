# Theme module. Fixture theme.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  slots = validTheme.slots // {
    zero = "204060";
  };
}
