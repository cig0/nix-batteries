# Theme module. Do not remove this header.
# 311 Amber CRT — vintage phosphor monitor aesthetic
{ }:
rec {
  # Preserve the existing 311amber rendering exactly.
  boldFactor = 1.0;
  dimFactor = 0.55;

  # Interactive selectors use a high-contrast theme-owned pair instead of
  # inferring UI roles from numbered slots. Consumers receive raw #RRGGBB.
  selection = {
    background = slots.four;
    foreground = "#000000";
  };

  slots = rec {
    zero = "#ffb343"; # Vibrant orange
    one = "#f8fafc"; # Muted-ish white
    two = "#0080ff"; # Pale-ish blue
    two_light = "#b1dafb"; # Light blue
    three = "#ff00ff"; # Magenta
    four = "#ffff00"; # Yellow
    five = "#ef4444"; # Red
    six = "#ffc0cb"; # Pink
    seven = "#00ff7f"; # Vibrant green

    bold_zero = zero;
    bold_one = one;
    bold_two = two;
    bold_two_light = two_light;
    bold_three = three;
    bold_four = four;
    bold_five = five;
    bold_six = six;
    bold_seven = seven;

    dimmed_zero = zero;
    dimmed_one = one;
  };
}
