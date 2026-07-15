{ ... }:
{
  shell = "nushell";
  print =
    text:
    let
      nushellText = builtins.replaceStrings [ "\\e" ] [ "\\u{1b}" ] text;
    in
    ''print --no-newline "${nushellText}"'';

  # Nushell reserves -h/--help for native custom-command help before the body runs.
  helpCheck = _: "# Nushell provides native -h/--help handling for custom commands.";
}
