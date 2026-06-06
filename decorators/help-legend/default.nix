/*
  === Help legend decorator ===

  Shared Nix functions for two-column help display layouts where a legend
  (key -> description mapping) drives column alignment and title centering.

  Command data, theme values, function names, aliases, and command behavior
  stay in the consuming module. Runtime syntax stays in libHelpLegendRenderer.
*/
{ ... }:
let
  libHelpLegendRenderer = {
    posix = import ./renderers/posix.nix { };
    fish = import ./renderers/fish.nix { };
    nushell = import ./renderers/nushell.nix { };
  };

  /*
    Repeat a character n times.

    Type: repeat :: int -> string -> string
  */
  repeat = n: s: builtins.concatStringsSep "" (builtins.genList (_: s) n);

  /*
    Find the maximum string length in a list.

    Type: maxStringLength :: [string] -> int
  */
  maxStringLength =
    list:
    builtins.foldl' (
      acc: s:
      let
        len = builtins.stringLength s;
      in
      if len > acc then len else acc
    ) 0 list;

  /*
    Compute layout metrics for a set of two-column help groups.

    Type: sectionLayout ::
      { groups :: [{ name :: string; cmds :: [string]; }]
      , descFn :: string -> string
      , indent ? 2
      , minGap ? 2
      } -> { descCol :: int; maxDescLen :: int; width :: int; padCmd :: string -> string }
  */
  sectionLayout =
    {
      descFn,
      groups,
      indent ? 2,
      minGap ? 2,
    }:
    let
      allCmds = builtins.concatLists (map (g: g.cmds) groups);
      descCol = indent + maxCmdLen + minGap;
      maxCmdLen = maxStringLength allCmds;
      maxDescLen = maxStringLength (map descFn allCmds);
      width = descCol + maxDescLen;
    in
    {
      inherit descCol maxDescLen width;
      padCmd = cmd: repeat (descCol - indent - builtins.stringLength cmd) " ";
    };

  maxInt = builtins.foldl' (acc: w: if w > acc then w else acc) 0;

  centerIn = width: title: repeat ((width - builtins.stringLength title) / 2) " ";

  /*
    Render a two-column help section with one or more named groups.
    `layout` is normally shared across all sections so descriptions align
    across the whole help screen.
  */
  mkHelpSection =
    {
      closing ? [ ],
      cmdColor,
      descFn,
      groups,
      headerColor,
      layout ? sectionLayout { inherit groups descFn; },
      renderer ? libHelpLegendRenderer.posix,
      reset,
    }:
    let
      allCmds = builtins.concatLists (map (g: g.cmds) groups);
      maxDescLen = maxStringLength (map descFn allCmds);
      width = layout.descCol + maxDescLen;
      row = cmd: renderer.print "\\n  ${cmdColor}${cmd}${reset}${layout.padCmd cmd}${descFn cmd}";
      group = g: [ (renderer.print "\\n${headerColor}${g.name}${reset}") ] ++ map row g.cmds;
      bodyLines =
        let
          gs = map group groups;
        in
        builtins.concatLists (
          if builtins.length gs == 0 then
            [ ]
          else
            [ (builtins.head gs) ] ++ map (g: [ (renderer.print "\\n") ] ++ g) (builtins.tail gs)
        );
    in
    {
      inherit width;
      text = ''
        ${builtins.concatStringsSep "\n" (
          builtins.concatLists [
            bodyLines
            closing
          ]
        )}
      '';
    };

  mkCenteredTitle =
    {
      color,
      leadingLines ? 1,
      renderer ? libHelpLegendRenderer.posix,
      reset,
      title,
      width,
    }:
    let
      pad = centerIn width title;
      leading = builtins.concatStringsSep "" (builtins.genList (_: "\\n") (leadingLines + 1));
    in
    renderer.print "${leading}${color}${pad}${title}${reset}";

  mkHelpCheck =
    {
      cmd,
      cmdColor,
      desc,
      layout,
      renderer ? libHelpLegendRenderer.posix,
      reset,
    }:
    renderer.helpCheck {
      inherit
        cmd
        cmdColor
        desc
        reset
        ;
      pad = layout.padCmd cmd;
    };

  enabledWidth = sections: maxInt (map (section: section.width) sections);
in
{
  inherit
    centerIn
    enabledWidth
    maxInt
    maxStringLength
    mkCenteredTitle
    mkHelpCheck
    mkHelpSection
    libHelpLegendRenderer
    repeat
    sectionLayout
    ;
}
