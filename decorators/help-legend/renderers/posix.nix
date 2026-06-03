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
    ''[[ "$1" == "-h" || "$1" == "--help" ]] && { printf '%b' "\n  ${cmdColor}${cmd}${reset}${pad}${desc}\n"; return 0; }'';
}
