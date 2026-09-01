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

  requiredSlots = [
    "zero"
    "one"
    "two"
    "three"
    "four"
    "five"
    "six"
    "seven"
    "bold_zero"
    "bold_one"
    "bold_two"
    "bold_three"
    "bold_four"
    "bold_five"
    "bold_six"
    "bold_seven"
    "dimmed_zero"
    "dimmed_one"
  ];
}
