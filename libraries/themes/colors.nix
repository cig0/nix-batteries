/*
  Color arithmetic used by ANSI presentation.

  This module knows how to parse and scale RGB values. It does not know about
  theme discovery, required slots, terminal escape codes, or public outputs.
*/
let
  hexDigitToInteger =
    digit:
    {
      "0" = 0;
      "1" = 1;
      "2" = 2;
      "3" = 3;
      "4" = 4;
      "5" = 5;
      "6" = 6;
      "7" = 7;
      "8" = 8;
      "9" = 9;
      a = 10;
      b = 11;
      c = 12;
      d = 13;
      e = 14;
      f = 15;
      A = 10;
      B = 11;
      C = 12;
      D = 13;
      E = 14;
      F = 15;
    }
    .${digit};

  hexStringToInteger =
    hexString:
    let
      stringLength = builtins.stringLength hexString;
      convertNextDigit =
        position: accumulatedValue:
        if position >= stringLength then
          accumulatedValue
        else
          convertNextDigit (position + 1) (
            accumulatedValue * 16 + hexDigitToInteger (builtins.substring position 1 hexString)
          );
    in
    convertNextDigit 0 0;
in
{
  hexColorToRgb = hexColor: {
    red = hexStringToInteger (builtins.substring 1 2 hexColor);
    green = hexStringToInteger (builtins.substring 3 2 hexColor);
    blue = hexStringToInteger (builtins.substring 5 2 hexColor);
  };

  scaleRgb =
    factor: rgb:
    let
      scaleChannel =
        channel:
        let
          scaledChannel = builtins.floor (builtins.mul channel factor);
        in
        if scaledChannel > 255 then 255 else scaledChannel;
    in
    {
      red = scaleChannel rgb.red;
      green = scaleChannel rgb.green;
      blue = scaleChannel rgb.blue;
    };
}
