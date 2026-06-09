/*
  CRT color palette.

  Amber phosphor monitor aesthetic — warm, saturated colors that
  evoke vintage terminal displays. Each entry generates bold, dimmed,
  and regular foreground variants when loaded by palette.nix.

  CRT colors are tuned for dark backgrounds with warm amber/green
  phosphor tones. Blue and magenta are shifted warmer compared to
  the Tailwind-inspired palette to maintain visual cohesion with
  the amber/yellow primary.

  To create a new palette: copy this file, adjust the hex values,
  and pass it to palette.nix as the `paletteFile` argument.
*/
{
  blue = "#5b8dd9";
  cyan = "#00b8b8";
  green = "#22c55e";
  grey = "#aaaaaa"
  magenta = "#cc66cc";
  orange = "#ff6600";
  red = "#ef4444";
  white = "#f8fafc";
  yellow = "#f59e0b";
}
