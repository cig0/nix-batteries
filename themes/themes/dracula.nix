# Theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (Dracula — dark purple, cyan accents).

  Slot | Color    | Role
  -----|----------|-------------------------------------------
  0    | cyan     | Primary accent (Cyan — success, headers)
  1    | white    | Text emphasis
  2    | magenta  | Tertiary accent (Purple)
  3    | green    | Callout / alternative highlight
  4    | yellow   | Warning / highlight
  5    | red      | Error / danger

  Non-bold slots follow the same numbering.
*/
{
  bold_zero = color.bold.cyan;
  bold_one = color.bold.white;
  bold_two = color.bold.magenta;
  bold_three = color.bold.green;
  bold_four = color.bold.yellow;
  bold_five = color.bold.red;
  zero = color.cyan;
  two = color.magenta;
  four = color.yellow;
}
