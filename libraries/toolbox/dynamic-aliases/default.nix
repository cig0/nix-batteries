/*
  Dynamic alias catalogue builder.

  Callers supply semantic entries and naming functions; this library returns
  aliases, help-legend data, and an optional group while rejecting collisions.
  It owns no shell rendering or command-discovery policy.
*/
{ lib }:
let
  countOccurrences =
    target: values: builtins.length (builtins.filter (value: value == target) values);

  stripNixSuffix = name: builtins.substring 0 (builtins.stringLength name - 4) name;
in
{
  discoverNixFileNames =
    {
      directory,
      excludeFiles ? [ "default.nix" ],
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
    rawArgs@{
      names ? if builtins.hasAttr "entries" rawArgs then builtins.attrNames entries else null,
      entries ? if builtins.hasAttr "names" rawArgs then lib.genAttrs names (_: null) else null,
      nameFor,
      valueFor,
      legendFor ? valueFor,
      groupName ? null,
      ...
    }:
    let
      resolvedNames =
        if names == null then throw "dynamicAliases.mk requires either `names` or `entries`." else names;

      resolvedEntries =
        if entries == null then
          throw "dynamicAliases.mk requires either `names` or `entries`."
        else
          entries;

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
      duplicateAliasNames = lib.unique (
        builtins.filter (aliasName: countOccurrences aliasName aliasNames > 1) aliasNames
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
