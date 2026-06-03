# ANSI theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (Nord — cold, icy blues).

  Slot | Color    | Role
  -----|----------|-------------------------------------------
  0    | blue     | Primary accent (Frost — success, headers)
  1    | white    | Text emphasis (Snow)
  2    | cyan     | Tertiary accent (Ice)
  3    | magenta  | Callout / alternative highlight (Aurora)
  4    | yellow   | Warning / highlight
  5    | red      | Error / danger

  Non-bold slots follow the same numbering.
*/
{
  bold_zero = color.bold.blue;
  bold_one = color.bold.white;
  bold_two = color.bold.cyan;
  bold_three = color.bold.magenta;
  bold_four = color.bold.yellow;
  bold_five = color.bold.red;
  zero = color.blue;
  two = color.cyan;
  four = color.yellow;
}
