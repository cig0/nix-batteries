/*
  Public provenance for provider-owned theme modules.

  resolver.nix supplies the exact discovery result and its logical source
  directory. Consumers can therefore report ownership without reconstructing
  paths from their own checkout layout.
*/
{
  discoveredThemes, # resolver.nix → discovery.nix result
  lib, # resolver.nix → nixpkgs.lib
  themeModuleSourceDirectory, # resolver.nix → published logical path
}:
lib.mapAttrs (themeName: _discoveredTheme: {
  provider = "nix-batteries";
  source = "${themeModuleSourceDirectory}/${themeName}.nix";
}) discoveredThemes
