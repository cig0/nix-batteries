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
      bold_zero = color.bold.cyan;
      bold_one = color.bold.white;
      bold_two = color.bold.magenta;
      bold_three = color.bold.green;
      bold_four = color.bold.yellow;
      bold_five = color.bold.red;
      bold_six = "";
      bold_seven = "";
      dimmed_zero = color.dimmed.cyan;
      dimmed_one = color.dimmed.white;
      zero = color.cyan;
      one = color.white;
      two = color.magenta;
      three = color.green;
      four = color.yellow;
      five = color.red;
    };
}
