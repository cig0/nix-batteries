/*
  Fish presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build native Fish help output.

  `escape` makes one literal text value safe inside the double-quoted
  `printf '%b'` payload. Fish expands `$` and honors backslash escapes in
  double quotes, so those are escaped; a backtick is left alone because Fish
  does not treat it as command substitution and would keep a backslash placed
  before it. A literal backslash is quadrupled so that both Fish's double-quote
  processing and `%b` leave one backslash.
*/
{ ... }:
let
  backslash = "\\";
  escape =
    builtins.replaceStrings
      [ backslash "$" "\"" ]
      [
        (backslash + backslash + backslash + backslash)
        (backslash + "$")
        (backslash + "\"")
      ];
in
{
  shell = "fish";
  inherit escape;
  print = text: ''printf '%b' "${text}"'';

  helpCheck =
    {
      cmd,
      cmdColor,
      desc,
      pad,
      indent ? "  ",
      reset,
    }:
    ''
      if test "$argv[1]" = "-h"; or test "$argv[1]" = "--help"
        printf '%b' "\n${indent}${cmdColor}${escape cmd}${reset}${pad}${escape desc}"
        printf '%b' "\n"
        return 0
      end
    '';
}
