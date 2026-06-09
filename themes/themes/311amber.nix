# Theme module. Do not remove this header.
# 311 Amber CRT — vintage phosphor monitor aesthetic
/*
  Override palette colors per-theme. Patched hex flows into
  color.* automatically:

    { }:
    {
      palette = "og";
      overrides = { blue = "#4488dd"; };
      dimFactor = 0.4;   # lower = dimmer (default: 0.55)
      slots = { color }:
      {
        bold_two = color.bold.blue;  # ← uses overridden #4488dd
      };
    }
*/
{ }:
{
  palette = "crt";
  overrides = {
    yellow = "#ffde21";
  };
  slots =
    { color }:
    {
      bold_zero = color.bold.orange;
      bold_one = color.bold.white;
      bold_two = color.bold.blue;
      bold_three = color.bold.magenta;
      bold_four = color.bold.blue;
      bold_five = color.bold.red;
      dimmed_zero = color.dimmed.orange;
      dimmed_one = color.grey;
      zero = color.orange;
      one = color.white;
      two = color.blue;
      three = color.magenta;
      four = color.yellow;
      five = color.red;
    };
}
