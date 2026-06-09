# Theme module. Do not remove this header.
# Steel — Tailwind palette with a muted blue override
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
  overrides = {
    blue = "#4a6fa5";
  };
  slots =
    { color }:
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
    };
}
