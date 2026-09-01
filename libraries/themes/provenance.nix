/*
  Public provenance for provider-owned theme modules.

  resolver.nix supplies the exact discovery result and its logical source
  directory. Consumers can therefore report ownership without reconstructing
  paths from their own checkout layout.
*/
{
  discoveredThemes,
  lib,
  themeModuleSourceDirectory,
}:
lib.mapAttrs (themeName: _discoveredTheme: {
  provider = "nix-nitro";
  source = "${themeModuleSourceDirectory}/${themeName}.nix";
}) discoveredThemes
