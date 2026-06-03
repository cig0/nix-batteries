{ ... }:
{
  shell = "nushell";
  print = text: ''print --no-newline "${text}"'';

  helpCheck =
    {
      cmd,
      cmdColor,
      desc,
      pad,
      reset,
    }:
    ''
      let __help_arg = ($args | get 0? | default "")
      if ($__help_arg == "-h" or $__help_arg == "--help") {
        print --no-newline "\n  ${cmdColor}${cmd}${reset}${pad}${desc}\n"
        return
      }
    '';
}
