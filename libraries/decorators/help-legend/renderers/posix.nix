/*
  POSIX presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build Bash and Zsh-compatible help output.
*/
{ ... }:
{
  shell = "posix";
  print = text: ''printf '%b' "${text}"'';

  helpCheck =
    {
      cmd,
      cmdColor,
      desc,
      pad,
      reset,
    }:
    ''[[ "$1" == "-h" || "$1" == "--help" ]] && { printf '%b' "\n  ${cmdColor}${cmd}${reset}${pad}${desc}"; printf '%b' "\n"; return 0; }'';
}
