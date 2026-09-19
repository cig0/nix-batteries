# Theme module. Fixture theme using a reserved dim_ role name.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = validTheme.roles // {
    dim_accent = "#204060";
  };
}
