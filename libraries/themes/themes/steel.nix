# Theme module. Do not remove this header.
# Steel — Tailwind palette with a muted blue override
/*
  Override palette colors per-theme. Patched hex flows into
  color.* automatically:

    { }:
    {
      palette = "fuel";
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
      bold_six = "";
      bold_seven = "";
      dimmed_zero = color.dimmed.blue;
      dimmed_one = color.dimmed.white;
      zero = color.blue;
      one = color.white;
      two = color.cyan;
      three = color.magenta;
      four = color.yellow;
      five = color.red;
    };
}
