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
  palette = "tailwind-inspired";
  slots =
    { color }:
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
    };
}
