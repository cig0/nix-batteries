# Theme module. Fixture theme with zero bold and dim factors.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  boldFactor = 0.0;
  dimFactor = 0.0;
}
