/*
  Fish presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build native Fish help output.
*/
{ ... }:
{
  shell = "fish";
  print = text: ''printf '%b' "${text}"'';

  helpCheck =
    {
      cmd,
      cmdColor,
      desc,
      pad,
      reset,
    }:
    ''
      if test "$argv[1]" = "-h"; or test "$argv[1]" = "--help"
        printf '%b' "\n  ${cmdColor}${cmd}${reset}${pad}${desc}"
        printf '%b' "\n"
        return 0
      end
    '';
}
