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
  # Slot and selection colors are always raw #RRGGBB source data.
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
        throw "Invalid ${context} slot '${colorName}': expected #RRGGBB, got ${actualValue}"
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

  # contract.nix is authoritative for the shared terminal-slot schema.
  # Report every omission together so a theme author can correct it in one pass.
  validateRequiredSlots =
    themeName: slots:
    let
      missingSlots = builtins.filter (
        requiredSlot: !(builtins.hasAttr requiredSlot slots)
      ) themeContract.requiredSlots;
    in
    if missingSlots == [ ] then
      slots
    else
      throw "Theme '${themeName}' is missing required slots: ${lib.concatStringsSep ", " missingSlots}";

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
    validateRequiredSlots
    validateScaleFactor
    validateSelectionColors
    ;
}
