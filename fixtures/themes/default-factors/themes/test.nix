# Theme module. Fixture theme relying on the contract's default factors.
{ }:
let
  validTheme = (import ../../valid/themes/test.nix) { };
in
builtins.removeAttrs validTheme [
  "boldFactor"
  "dimFactor"
]
