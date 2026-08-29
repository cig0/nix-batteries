# Theme module. Fixture theme with an invalid selection foreground.
{ }:
let
  validTheme = import ../../valid/themes/test.nix { };
in
validTheme
// {
  selection = {
    background = validTheme.slots.seven;
    foreground = "black";
  };
}
