/*
  Dynamic alias catalogue builder.

  Callers supply semantic entries and naming functions; this library returns
  aliases, help-legend data, and an optional group while rejecting collisions.
  It owns no shell rendering or command-discovery policy.
*/
{ lib }:
let
  stripNixSuffix = name: builtins.substring 0 (builtins.stringLength name - 4) name;
in
{
  discoverNixFileNames =
    {
      directory, # caller args → nix file directory
      excludeFiles ? [ "default.nix" ], # caller args → filenames to skip
    }:
    let
      entries = builtins.readDir directory;
      fileNames = builtins.attrNames entries;
      isDiscoverableNixFile =
        name:
        entries.${name} == "regular" && lib.hasSuffix ".nix" name && !(builtins.elem name excludeFiles);
    in
    map stripNixSuffix (builtins.filter isDiscoverableNixFile fileNames);

  mk =
    {
      names ? null, # caller args → ordered selection of source names
      entries ? null, # caller args → source values, keyed by name
      nameFor, # caller args → alias name renderer
      valueFor, # caller args → alias command renderer
      legendFor ? valueFor, # caller args → help legend renderer
      groupName ? null, # caller args → help section group label
      ...
    }:
    let
      resolvedNames =
        if names != null then
          names
        else if entries != null then
          builtins.attrNames entries
        else
          throw "dynamicAliases.mk requires either `names` or `entries`.";

      # With both arguments, names selects/orders entries; missing keys fail below.
      resolvedEntries = if entries != null then entries else lib.genAttrs resolvedNames (_: null);

      rows = map (
        name:
        let
          entry =
            if builtins.hasAttr name resolvedEntries then
              resolvedEntries.${name}
            else
              throw "dynamicAliases.mk missing entry for `${name}`.";
        in
        {
          inherit name entry;
          aliasName = nameFor name entry;
          value = valueFor name entry;
          legendValue = legendFor name entry;
        }
      ) resolvedNames;

      aliasNames = map (row: row.aliasName) rows;
      indexedAliases = lib.imap0 (index: aliasName: { inherit index aliasName; }) aliasNames;
      aliasesByName = builtins.groupBy (row: row.aliasName) indexedAliases;
      # Emit duplicates in first-occurrence order, as in the original diagnostic.
      duplicateAliasNames = map (row: row.aliasName) (
        builtins.filter (
          row:
          let
            matchingAliases = aliasesByName.${row.aliasName};
          in
          builtins.length matchingAliases > 1 && (builtins.head matchingAliases).index == row.index
        ) indexedAliases
      );
    in
    if duplicateAliasNames != [ ] then
      throw "dynamicAliases.mk generated duplicate alias name(s): ${lib.concatStringsSep ", " duplicateAliasNames}"
    else
      {
        names = resolvedNames;
        inherit aliasNames;

        # toolbox/dynamic-aliases -> consumer shell aliases
        aliases = builtins.listToAttrs (
          map (row: {
            name = row.aliasName;
            value = row.value;
          }) rows
        );

        # toolbox/dynamic-aliases -> consumer help legend
        legend = builtins.listToAttrs (
          map (row: {
            name = row.aliasName;
            value = row.legendValue;
          }) rows
        );

        # toolbox/dynamic-aliases -> help section group
        group =
          if groupName == null then
            null
          else
            {
              name = groupName;
              cmds = aliasNames;
            };
      };
}
