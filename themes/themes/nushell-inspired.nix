# ANSI theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (nushell-inspired — the canonical default theme).

  Slot | Color    | Role
  -----|----------|-------------------------------------------
  0    | green    | Primary accent (success, headers, positive)
  1    | white    | Text emphasis
  2    | blue     | Tertiary accent (e.g. NixOS section)
  3    | magenta  | Callout / alternative highlight
  4    | yellow   | Warning / highlight
  5    | red      | Error / danger

  Non-bold slots follow the same numbering.
*/
{
  bold_zero = color.bold.green;
  bold_one = color.bold.white;
  bold_two = color.bold.blue;
  bold_three = color.bold.magenta;
  bold_four = color.bold.yellow;
  bold_five = color.bold.red;
  zero = color.green;
  one = color.white;
  two = color.blue;
  three = color.magenta;
  four = color.yellow;
  five = color.red;
}
