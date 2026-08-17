# Theme module. Do not remove this header.
# 311 Amber CRT — vintage phosphor monitor aesthetic
{ }:
{
  # Preserve the existing 311amber rendering exactly.
  boldFactor = 1.0;
  dimFactor = 0.55;

  slots = rec {
    zero = "#ffb343"; # Orange
    one = "#f8fafc"; # White
    two = "#5b8dd9"; # Blue
    two_light = "#b1dafb"; # Light blue
    three = "#cc66cc"; # Magenta
    four = "#ffde21"; # Yellow
    five = "#ef4444"; # Red
    six = "#ffa6c9"; #  Pink
    seven = "#00ff7f"; # Green

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
