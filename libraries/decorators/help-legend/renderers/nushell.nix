/*
  Nushell presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build native Nushell help output and preserve Nushell's help
  handling contract.
*/
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
