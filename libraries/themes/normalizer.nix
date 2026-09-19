/*
  Canonical representation of one discovered theme.

  Contract defaults come from contract.nix and every supplied value passes
  through assertions.nix. Color consumers and ANSI presentation therefore
  receive one predictable shape regardless of optional source fields.
*/
{
  themeAssertions, # resolver.nix → assertions.nix
  themeContract, # resolver.nix → contract.nix
}:
themeName: discoveredTheme:
let
  boldFactor = themeAssertions.validateScaleFactor "theme '${themeName}' boldFactor" (
    discoveredTheme.boldFactor or themeContract.defaultBoldFactor
  );
  dimFactor = themeAssertions.validateScaleFactor "theme '${themeName}' dimFactor" (
    discoveredTheme.dimFactor or themeContract.defaultDimFactor
  );
  roles = themeAssertions.validateHexColors "theme '${themeName}'" (
    themeAssertions.validateRoleNames themeName (
      themeAssertions.validateRequiredRoles themeName (
        themeAssertions.validateRoleSource themeName discoveredTheme
      )
    )
  );
  selection = themeAssertions.validateSelectionColors themeName (discoveredTheme.selection or null);
in
# Force the complete source contract before publishing normalized theme data.
builtins.deepSeq
  [
    boldFactor
    dimFactor
    roles
    selection
  ]
  {
    inherit
      boldFactor
      dimFactor
      roles
      selection
      ;
  }
