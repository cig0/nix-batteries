# ANSI theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (Catppuccin Mocha — soft pastels, Mauve accent).

  Slot | Color    | Role
  -----|----------|-------------------------------------------
  0    | magenta  | Primary accent (Mauve — success, headers)
  1    | white    | Text emphasis
  2    | cyan     | Tertiary accent (Teal)
  3    | blue     | Callout / alternative highlight (Sapphire)
  4    | yellow   | Warning / highlight (Peach)
  5    | red      | Error / danger

  Non-bold slots follow the same numbering.
*/
{
  bold_zero = color.bold.magenta;
  bold_one = color.bold.white;
  bold_two = color.bold.cyan;
  bold_three = color.bold.blue;
  bold_four = color.bold.yellow;
  bold_five = color.bold.red;
  zero = color.magenta;
  two = color.cyan;
  four = color.yellow;
}
