# Theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (311 Amber CRT — vintage phosphor monitor aesthetic).

  Slot | Color           | Role
  -----|----------------|-------------------------------------------
  0    | bold orange    | Primary accent (success, headers, positive)
  1    | bold white     | Text emphasis
  2    | bold blue      | Tertiary accent (e.g. NixOS section)
  3    | bold magenta   | Callout / alternative highlight
  4    | bold yellow    | Warning / highlight
  5    | bold red       | Error / danger

  Non-bold slots follow the same numbering.
  Dimmed slots use dimmed orange for accent, grey for muted text.
*/
{
  bold_zero = color.bold.orange;
  bold_one = color.bold.white;
  bold_two = color.bold.blue;
  bold_three = color.bold.magenta;
  bold_four = color.bold.yellow;
  bold_five = color.bold.red;
  dimmed_zero = color.dimmed.orange;
  dimmed_one = color.grey;
  zero = color.orange;
  one = color.white;
  two = color.blue;
  three = color.magenta;
  four = color.yellow;
  five = color.red;
}
