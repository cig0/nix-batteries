# ANSI theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (Gruvbox Dark — warm, retro, amber accent).

  Slot | Color    | Role
  -----|----------|-------------------------------------------
  0    | yellow   | Primary accent (Amber — success, headers)
  1    | white    | Text emphasis
  2    | cyan     | Tertiary accent (Aqua)
  3    | green    | Callout / alternative highlight
  4    | magenta  | Warning / highlight (Purple)
  5    | red      | Error / danger

  Non-bold slots follow the same numbering.
*/
{
  bold_zero = color.bold.yellow;
  bold_one = color.bold.white;
  bold_two = color.bold.cyan;
  bold_three = color.bold.green;
  bold_four = color.bold.magenta;
  bold_five = color.bold.red;
  zero = color.yellow;
  two = color.cyan;
  four = color.magenta;
}
