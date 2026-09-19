# Theme module. Fixture theme with an invalid selection foreground.
{ }:
let
  validTheme = import ../../valid/themes/test.nix { };
in
validTheme
// {
  selection = {
    background = validTheme.roles.context;
    foreground = "black";
  };
}
