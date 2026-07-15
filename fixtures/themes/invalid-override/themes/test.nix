# Theme module. Fixture theme.
{ }:
{
  palette = "base";
  overrides = {
    accent = "not-a-color";
  };
  slots = { color }: { zero = color.accent; };
}
