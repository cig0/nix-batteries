/*
  POSIX presentation adapter for help-legend.

  help-legend/default.nix discovers this renderer and uses its string-returning
  functions to build help output for POSIX-compatible shells such as dash,
  bash, and zsh. The guard and the printing primitive stay within the POSIX
  shell grammar.

  `escape` makes one literal text value safe inside the double-quoted
  `printf '%b'` payload. Shell expansion characters are backslash-escaped, and
  a literal backslash becomes the octal escape `\0134`, which the shell's
  double quotes pass through unchanged and `%b` renders as one backslash.

  `printf '%b'` recognises `\e` only in shells that extend POSIX (bash, zsh);
  dash prints it literally. Theme colour and mode values are therefore rewritten
  to the portable `\033`, which every tested implementation renders as ESC.
  Payload text can never forge that sequence because every payload backslash
  appears as `\0134`, so the rewrite only ever touches colour input.
*/
{ ... }:
let
  backslash = "\\";
  escape =
    builtins.replaceStrings
      [ backslash "$" "`" "\"" ]
      [
        "\\0134"
        (backslash + "$")
        (backslash + "`")
        (backslash + "\"")
      ];
  portableEscapes = builtins.replaceStrings [ "\\e" ] [ "\\033" ];
in
{
  shell = "posix";
  inherit escape;
  print = text: ''printf '%b' "${portableEscapes text}"'';

  helpCheck =
    {
      cmd,
      cmdColor,
      desc,
      pad,
      indent ? "  ",
      reset,
    }:
    let
      payload = "\\n${indent}${cmdColor}${escape cmd}${reset}${pad}${escape desc}";
    in
    ''{ [ "''${1-}" = "-h" ] || [ "''${1-}" = "--help" ]; } && { printf '%b' "${portableEscapes payload}"; printf '%b' "\n"; return 0; }'';
}
