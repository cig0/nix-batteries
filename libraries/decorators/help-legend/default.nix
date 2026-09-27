/*
  === Help legend decorator ===

  Shared Nix functions for two-column help display layouts where a legend
  (key -> description mapping) drives column alignment and title centering.

  Command data, theme values, function names, aliases, and command behavior
  stay in the consuming module. Runtime syntax stays in libHelpLegendRenderer.
*/
{ ... }:
let
  rendererSet = {
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
      allCmds = builtins.concatLists (map (group: group.cmds) groups);
      descCol = indent + maxCmdLen + minGap;
      maxCmdLen = maxStringLength allCmds;
      maxDescLen = maxStringLength (map descFn allCmds);
      width = descCol + maxDescLen;
    in
    assert builtins.isInt indent && indent >= 0;
    assert builtins.isInt minGap && minGap >= 0;
    {
      inherit descCol maxDescLen width;
      indentText = repeat indent " ";
      padCmd = cmd: repeat (descCol - indent - builtins.stringLength cmd) " ";
    };

  maxInt = builtins.foldl' (maximum: width: if width > maximum then width else maximum) 0;

  centerIn =
    width: title:
    repeat (maxInt [
      0
      ((width - builtins.stringLength title) / 2)
    ]) " ";

  /*
    Render a two-column help section with one or more named groups.
    `layout` is normally shared across all sections so descriptions align
    across the whole help screen.
  */
  mkHelpSection =
    {
      closing ? [ ],
      theme ? null,
      cmdColor ?
        if theme == null then
          throw "mkHelpSection requires cmdColor or theme"
        else
          theme.theme.bold.emphasis,
      commandParts ? cmd: [
        {
          text = cmd;
          color = cmdColor;
        }
      ],
      descFn,
      groups,
      headerColor ?
        if theme == null then
          throw "mkHelpSection requires headerColor or theme"
        else
          theme.theme.bold.accent,
      layout ? sectionLayout { inherit groups descFn; },
      libHelpLegendRenderer ? rendererSet.posix,
      reset ? if theme == null then throw "mkHelpSection requires reset or theme" else theme.mode.reset,
    }:
    let
      allCmds = builtins.concatLists (map (group: group.cmds) groups);
      maxDescLen = maxStringLength (map descFn allCmds);
      width = layout.descCol + maxDescLen;
      # Command names and descriptions are caller-authored text. The renderer
      # escapes them for its shell before they enter the printed payload.
      escape = libHelpLegendRenderer.escape;
      row =
        cmd:
        let
          parts = commandParts cmd;
          plainCommand = builtins.concatStringsSep "" (map (part: part.text) parts);
          styledCommand = builtins.concatStringsSep "" (map (part: "${part.color}${escape part.text}") parts);
        in
        assert plainCommand == cmd;
        libHelpLegendRenderer.print "\\n${layout.indentText or "  "}${styledCommand}${reset}${layout.padCmd cmd}${escape (descFn cmd)}";
      group =
        entry:
        [ (libHelpLegendRenderer.print "\\n${headerColor}${escape entry.name}${reset}") ]
        ++ map row entry.cmds;
      bodyLines =
        let
          renderedGroups = map group groups;
        in
        builtins.concatLists (
          if builtins.length renderedGroups == 0 then
            [ ]
          else
            [ (builtins.head renderedGroups) ]
            ++ map (rows: [ (libHelpLegendRenderer.print "\\n") ] ++ rows) (builtins.tail renderedGroups)
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
      theme ? null,
      color ?
        if theme == null then throw "mkCenteredTitle requires color or theme" else theme.theme.bold.accent,
      leadingLines ? 1,
      # Exact count; the older leadingLines parameter counts additional breaks.
      leadingNewlines ? leadingLines + 1,
      libHelpLegendRenderer ? rendererSet.posix,
      reset ? if theme == null then throw "mkCenteredTitle requires reset or theme" else theme.mode.reset,
      title,
      width,
    }:
    let
      pad = centerIn width title;
      leading = repeat leadingNewlines "\\n";
    in
    assert builtins.isInt leadingNewlines && leadingNewlines >= 0;
    libHelpLegendRenderer.print "${leading}${color}${pad}${libHelpLegendRenderer.escape title}${reset}";

  mkHelpCheck =
    {
      cmd,
      cmdColor,
      desc,
      layout,
      libHelpLegendRenderer ? rendererSet.posix,
      reset,
    }:
    libHelpLegendRenderer.helpCheck {
      inherit
        cmd
        cmdColor
        desc
        reset
        ;
      pad = layout.padCmd cmd;
      indent = layout.indentText or "  ";
    };

  # Callers supply already-filtered sections; retain the public compatibility name.
  maximumSectionWidth = sections: maxInt (map (section: section.width) sections);
in
{
  inherit
    centerIn
    maxInt
    maxStringLength
    mkCenteredTitle
    mkHelpCheck
    mkHelpSection
    repeat
    sectionLayout
    ;
  enabledWidth = maximumSectionWidth;
  libHelpLegendRenderer = rendererSet;
}
