/*
  Nushell presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build native Nushell help output and preserve Nushell's help
  handling contract.

  `escape` makes one literal text value safe inside the double-quoted
  `print --no-newline` payload. Nushell double-quoted strings process `\\` and
  `\"` escapes, but leave `$` and backticks literal and reject a
  backslash-escaped backtick, so only the backslash and the double quote are
  escaped. A literal backslash is emitted as `\u{5c}` rather than `\\` so it
  cannot recombine with the `\e` color-code rewrite that `print` performs.
*/
{ ... }:
let
  backslash = "\\";
  escape =
    builtins.replaceStrings
      [ backslash "\"" ]
      [
        "\\u{5c}"
        (backslash + "\"")
      ];
in
{
  shell = "nushell";
  inherit escape;
  print =
    text:
    let
      nushellText = builtins.replaceStrings [ "\\e" ] [ "\\u{1b}" ] text;
    in
    ''print --no-newline "${nushellText}"'';

  # Nushell reserves -h/--help for native custom-command help before the body runs.
  helpCheck = _: "# Nushell provides native -h/--help handling for custom commands.";
}
