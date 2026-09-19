# Theme module. Fixture theme using a reserved bold_ role name.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = validTheme.roles // {
    bold_accent = "#204060";
  };
}
