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
        printf '%b' "\n  ${cmdColor}${cmd}${reset}${pad}${desc}\n"
        return 0
      end
    '';
}
