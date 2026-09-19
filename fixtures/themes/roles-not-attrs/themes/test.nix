# Theme module. Fixture theme whose roles are not an attribute set.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = "#204060";
}
