# Theme module. Fixture theme.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
validTheme
// {
  roles = builtins.removeAttrs validTheme.roles [ "context" ];
}
