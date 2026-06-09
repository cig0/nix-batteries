# Theme module. Do not remove this header.
{ color }:
/*
  Slot assignments (311 Amber CRT — vintage phosphor monitor aesthetic).

  Slot | Color         | Role
  -----|--------------|-------------------------------------------
  0    | bold green   | Primary accent (brand identity, success)
  1    | bold white   | Text emphasis (copyright, notices)
  2    | bold yellow  | Strong highlight (lookups, call-to-action)
  3    | yellow       | Informational body text (descriptions)
  4    | dimmed yellow| Warning / subtle markers (amber tint)
  5    | bold red     | Error / danger

  Non-bold slots follow the same numbering.
  Dimmed slots use dimmed green for accent, grey for muted text.
*/
{
  bold_zero = color.bold.green;
  bold_one = color.bold.white;
  bold_two = color.bold.yellow;
  bold_three = color.yellow;
  bold_four = color.dimmed.yellow;
  bold_five = color.bold.red;
  dimmed_zero = color.dimmed.green;
  dimmed_one = color.grey;
  zero = color.green;
  one = color.white;
  two = color.yellow;
  four = color.dimmed.yellow;
}
