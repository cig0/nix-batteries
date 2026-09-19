/*
  Theme source validation boundary.

  normalizer.nix calls these checks while constructing one canonical theme
  definition. This module owns failure policy only: it neither supplies
  defaults nor renders consumer-facing values.
*/
{
  lib, # resolver.nix → nixpkgs.lib
  themeContract, # resolver.nix → contract.nix
}:
let
  # Role and selection colors are always raw #RRGGBB source data.
  # ANSI conversion is deliberately owned by ansi-renderer.nix.
  validateHexColors =
    context:
    lib.mapAttrs (
      colorName: colorValue:
      if builtins.isString colorValue && builtins.match "^#[0-9a-fA-F]{6}$" colorValue != null then
        colorValue
      else
        let
          actualValue =
            if builtins.isString colorValue then builtins.toJSON colorValue else builtins.typeOf colorValue;
        in
        throw "Invalid ${context} color '${colorName}': expected #RRGGBB, got ${actualValue}"
    );

  # boldFactor and dimFactor tune presentation, but themes own their values.
  # Negative values would produce invalid color-channel semantics.
  validateScaleFactor =
    context: factor:
    if (builtins.isInt factor || builtins.isFloat factor) && factor >= 0 then
      factor
    else
      let
        actualValue =
          if builtins.isInt factor || builtins.isFloat factor then
            toString factor
          else if builtins.isString factor then
            builtins.toJSON factor
          else
            builtins.typeOf factor;
      in
      throw "Invalid ${context}: expected a non-negative number, got ${actualValue}";

  # A theme declares its semantic roles in one attribute set. Themes written
  # against the removed ordinal-slot contract fail here rather than silently
  # resolving to an empty palette.
  validateRoleSource =
    themeName: discoveredTheme:
    if !(builtins.hasAttr "roles" discoveredTheme) then
      throw "Theme '${themeName}' does not declare 'roles'"
    else if !(builtins.isAttrs discoveredTheme.roles) then
      throw "Invalid theme '${themeName}' roles: expected an attribute set, got ${builtins.typeOf discoveredTheme.roles}"
    else
      discoveredTheme.roles;

  # contract.nix is authoritative for the shared semantic role vocabulary.
  # Report every omission together so a theme author can correct it in one pass.
  validateRequiredRoles =
    themeName: roles:
    let
      missingRoles = builtins.filter (
        requiredRole: !(builtins.hasAttr requiredRole roles)
      ) themeContract.requiredRoles;
    in
    if missingRoles == [ ] then
      roles
    else
      throw "Theme '${themeName}' is missing required roles: ${lib.concatStringsSep ", " missingRoles}";

  /*
    ansi-renderer.nix publishes <role>, bold_<role> and dim_<role> for every
    declared role, and resolver.nix publishes raw roles beside the optional
    selection pair. Authored names that reuse those reserved forms would make
    one entry overwrite another, so reject them with the offending keys named.
  */
  validateRoleNames =
    themeName: roles:
    let
      reservedNames = builtins.filter (
        roleName:
        builtins.elem roleName themeContract.reservedRoleNames
        || builtins.any (prefix: lib.hasPrefix prefix roleName) themeContract.reservedRolePrefixes
      ) (builtins.attrNames roles);
    in
    if reservedNames == [ ] then
      roles
    else
      throw "Theme '${themeName}' uses reserved role names: ${lib.concatStringsSep ", " reservedNames}";

  # Selection colors are optional, but a supplied pair must be complete and
  # use only the explicit UI roles from contract.nix; consumers never infer one.
  validateSelectionColors =
    themeName: selection:
    if selection == null then
      null
    else if !builtins.isAttrs selection then
      throw "Invalid theme '${themeName}' selection: expected an attribute set"
    else
      let
        suppliedSelectionFields = builtins.attrNames selection;
        missingSelectionFields = builtins.filter (
          field: !(builtins.hasAttr field selection)
        ) themeContract.requiredSelectionFields;
        unsupportedSelectionFields = builtins.filter (
          field: !(builtins.elem field themeContract.requiredSelectionFields)
        ) suppliedSelectionFields;
      in
      if missingSelectionFields != [ ] then
        throw "Theme '${themeName}' selection is missing fields: ${lib.concatStringsSep ", " missingSelectionFields}"
      else if unsupportedSelectionFields != [ ] then
        throw "Theme '${themeName}' selection has unsupported fields: ${lib.concatStringsSep ", " unsupportedSelectionFields}"
      else
        validateHexColors "theme '${themeName}' selection" selection;
in
{
  # normalizer.nix composes these checks with contract defaults into one theme.
  inherit
    validateHexColors
    validateRequiredRoles
    validateRoleNames
    validateRoleSource
    validateScaleFactor
    validateSelectionColors
    ;
}
