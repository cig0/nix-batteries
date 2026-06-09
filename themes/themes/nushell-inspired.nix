# Theme module. Do not remove this header.
/*
  Override palette colors per-theme. Patched hex flows into
  color.* automatically:

    { }:
    {
      palette = "og";
      overrides = { blue = "#4488dd"; };
      slots = { color }:
      {
        bold_two = color.bold.blue;  # ← uses overridden #4488dd
      };
    }
*/
{ }:
{
  palette = "og";
  slots =
    { color }:
    {
      bold_zero = color.bold.green;
      bold_one = color.bold.white;
      bold_two = color.bold.blue;
      bold_three = color.bold.magenta;
      bold_four = color.bold.yellow;
      bold_five = color.bold.red;
      dimmed_zero = color.dimmed.green;
      dimmed_one = color.dimmed.white;
      zero = color.green;
      one = color.white;
      two = color.blue;
      three = color.magenta;
      four = color.yellow;
      five = color.red;
    };
}
