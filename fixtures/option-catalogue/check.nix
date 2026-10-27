# Standalone entry point for the direct-import option-catalogue fixture.
let
  flake = builtins.getFlake (toString ../..);
  cases = import ./. {
    lib = flake.inputs.nixpkgs.lib;
    optionCatalogue = import ../../libraries/toolbox/option-catalogue;
  };
  failures = builtins.filter (name: !cases.${name}) (builtins.attrNames cases);
in
if failures == [ ] then
  true
else
  throw "option-catalogue fixture failures: ${builtins.concatStringsSep ", " failures}"
