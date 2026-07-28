# Theme module. Do not remove this header.
# Nushell inspired — terminal colors matching Nushell's default color roles
{ }:
{
  boldFactor = 1.0;
  dimFactor = 0.55;

  slots = rec {
    zero = "#00cd00"; # Green
    one = "#ffffff"; # White
    two = "#0000ee"; # Blue
    three = "#cd00cd"; # Purple
    four = "#cdcd00"; # Yellow
    five = "#cd0000"; # Red
    six = "#ff87ff"; # Light purple
    seven = "#00cdcd"; # Cyan

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
