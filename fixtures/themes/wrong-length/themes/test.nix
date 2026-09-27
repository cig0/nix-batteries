# Theme module. Fixture theme.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = validTheme.roles // {
    accent = "#20406";
  };
}
