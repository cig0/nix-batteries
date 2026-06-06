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
    args@{
      nameFor,
      valueFor,
      legendFor ? valueFor,
      groupName ? null,
      ...
    }:
    let
      names =
        if builtins.hasAttr "names" args then
          args.names
        else if builtins.hasAttr "entries" args then
          builtins.attrNames args.entries
        else
          throw "dynamicAliases.mk requires either `names` or `entries`.";

      entries = if builtins.hasAttr "entries" args then args.entries else lib.genAttrs names (_: null);

      rows = map (
        name:
        let
          entry =
            if builtins.hasAttr name entries then
              entries.${name}
            else
              throw "dynamicAliases.mk missing entry for `${name}`.";
        in
        {
          inherit name entry;
          aliasName = nameFor name entry;
          value = valueFor name entry;
          legendValue = legendFor name entry;
        }
      ) names;

      aliasNames = map (row: row.aliasName) rows;
      duplicateAliasNames = lib.unique (
        builtins.filter (aliasName: countOccurrences aliasName aliasNames > 1) aliasNames
      );
    in
    if duplicateAliasNames != [ ] then
      throw "dynamicAliases.mk generated duplicate alias name(s): ${lib.concatStringsSep ", " duplicateAliasNames}"
    else
      {
        inherit names aliasNames;

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
