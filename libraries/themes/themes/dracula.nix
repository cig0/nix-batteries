# Theme module. Do not remove this header.
# Dracula — high-contrast dark theme with cyan and pink accents
{ }:
{
  boldFactor = 1.0;
  dimFactor = 0.55;

  slots = rec {
    zero = "#8be9fd"; # Cyan
    one = "#f8f8f2"; # Foreground
    two = "#ff79c6"; # Pink
    three = "#50fa7b"; # Green
    four = "#f1fa8c"; # Yellow
    five = "#ff5555"; # Red
    six = "#ffb86c"; # Orange
    seven = "#bd93f9"; # Purple

    bold_zero = zero;
    bold_one = one;
    bold_two = two;
    bold_three = three;
    bold_four = four;
    bold_five = five;
    bold_six = six;
    bold_seven = seven;

    dimmed_zero = zero;
    dimmed_one = one;
  };
}
