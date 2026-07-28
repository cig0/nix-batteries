# Theme module. Do not remove this header.
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
  palette = "fuel";
  slots =
    { color }:
    {
      bold_zero = color.bold.magenta;
      bold_one = color.bold.white;
      bold_two = color.bold.cyan;
      bold_three = color.bold.blue;
      bold_four = color.bold.yellow;
      bold_five = color.bold.red;
      bold_six = "";
      bold_seven = "";
      dimmed_zero = color.dimmed.magenta;
      dimmed_one = color.dimmed.white;
      zero = color.magenta;
      one = color.white;
      two = color.cyan;
      three = color.blue;
      four = color.yellow;
      five = color.red;
    };
}
