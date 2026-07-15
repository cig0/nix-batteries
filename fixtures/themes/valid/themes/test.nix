# Theme module. Fixture theme.
{ }:
{
  palette = "base";
  overrides = {
    accent = "#abcdef";
  };
  slots =
    { color }:
    {
      bold_zero = color.bold.blue;
      zero = color.accent;
    };
}
