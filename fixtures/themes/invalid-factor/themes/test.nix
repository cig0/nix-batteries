# Theme module. Fixture theme.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  boldFactor = -1.0;
}
