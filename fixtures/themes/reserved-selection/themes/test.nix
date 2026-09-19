# Theme module. Fixture theme using the reserved role name 'selection'.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = validTheme.roles // {
    selection = "#204060";
  };
}
