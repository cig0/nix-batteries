/*
  Passive data that defines the source contract shared by every theme.

  assertions.nix consumes this contract when validating discovered theme
  modules. Keeping these values here prevents validation policy from being
  hidden among discovery or ANSI presentation logic.
*/
{
  defaultBoldFactor = 1.0;
  defaultDimFactor = 0.55;

  requiredSelectionFields = [
    "background"
    "foreground"
  ];

  /*
    Semantic roles every theme must declare. Themes may add further roles;
    ansi-renderer.nix derives each role's presentations mechanically, so this
    list is the authored vocabulary, not the rendered one.
  */
  requiredRoles = [
    "accent"
    "emphasis"
    "option"
    "success"
    "value"
    "warning"
    "error"
    "notice"
    "context"
  ];

  # Role names that would collide with generated presentations or with the
  # raw selection pair once roles and selection share one colors attribute set.
  reservedRoleNames = [ "selection" ];
  reservedRolePrefixes = [
    "bold_"
    "dim_"
  ];
}
