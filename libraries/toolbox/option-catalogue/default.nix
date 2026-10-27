/*
  Caller-owned evaluated options → project → metadata lists → list / describe.
  Supplier membership and evaluation stay with the caller; this library only
  traverses declarations and selects metadata, without reading option values.
*/
{ lib }:
let
  project =
    options:
    let
      documentedOptions = lib.optionAttrSetToDocList options;
      # Upstream still lists visible children beneath an internal submodule.
      internalOptionPaths = map (option: option.loc) (
        lib.filter (option: option.internal) documentedOptions
      );
      isInsideInternalOption =
        option:
        lib.any (
          internalPath: lib.take (builtins.length internalPath) option.loc == internalPath
        ) internalOptionPaths;
      publicOptions = lib.filter (
        option: option.visible && !option.internal && !isInsideInternalOption option
      ) documentedOptions;
    in
    map (option: {
      inherit (option)
        name
        type
        description
        readOnly
        ;
      path = option.loc;
      declarations = map toString option.declarations;
    }) publicOptions;

  optionName =
    option:
    if builtins.isAttrs option && builtins.isString (option.name or null) then
      option.name
    else
      throw "optionCatalogue: expected an option record with a string name";

  checkedRecord =
    option:
    if
      builtins.isAttrs option
      &&
        builtins.attrNames option == [
          "declarations"
          "description"
          "name"
          "path"
          "readOnly"
          "type"
        ]
      && builtins.isString option.name
      && builtins.isList option.path
      && builtins.all builtins.isString option.path
      && (option.type == null || builtins.isString option.type)
      && (option.description == null || builtins.isString option.description)
      && builtins.isList option.declarations
      && builtins.all builtins.isString option.declarations
      && builtins.isBool option.readOnly
    then
      option
    else
      throw "optionCatalogue: invalid metadata record for ${builtins.toJSON (optionName option)}";

  checkedList =
    source: options:
    if builtins.isList options then
      options
    else
      throw "optionCatalogue: expected a metadata list for ${builtins.toJSON source}";

  list =
    {
      allOptions,
      optionsBySource ? { },
      sources ? null,
      prefix ? "",
    }:
    let
      selectedSources =
        if sources == null then
          [
            {
              source = "complete catalogue";
              options = allOptions;
            }
          ]
        else if !(builtins.isList sources && builtins.all builtins.isString sources) then
          throw "optionCatalogue.list: sources must be null or a list of strings"
        else if sources == [ ] then
          [ ]
        else if !builtins.isAttrs optionsBySource then
          throw "optionCatalogue.list: optionsBySource must be an attribute set"
        else
          let
            sourceNames = lib.unique (lib.sort builtins.lessThan sources);
            unknownSources = lib.filter (name: !(builtins.hasAttr name optionsBySource)) sourceNames;
          in
          if unknownSources != [ ] then
            throw (
              "optionCatalogue.list: unknown sources ${builtins.toJSON unknownSources}; "
              + "available sources: ${builtins.toJSON (builtins.attrNames optionsBySource)}"
            )
          else
            map (source: {
              inherit source;
              options = optionsBySource.${source};
            }) sourceNames;

      matchingOptions = lib.concatMap (
        selection:
        map
          (option: {
            inherit option;
            inherit (selection) source;
          })
          (
            lib.filter (option: lib.hasPrefix prefix (optionName option)) (
              checkedList selection.source selection.options
            )
          )
      ) selectedSources;

      # Group once by component path; preserve first occurrence order separately.
      indexedOptions = lib.imap0 (
        index: entry:
        let
          option = checkedRecord entry.option;
        in
        {
          inherit index option;
          inherit (entry) source;
          pathKey = builtins.toJSON option.path;
        }
      ) matchingOptions;
      optionsByPath = builtins.groupBy (entry: entry.pathKey) indexedOptions;
      uniqueOptions = lib.filter (
        entry:
        let
          first = builtins.head optionsByPath.${entry.pathKey};
        in
        if first.option != entry.option then
          throw (
            "optionCatalogue.list: conflicting metadata at ${entry.pathKey} from "
            + "${builtins.toJSON first.source} and ${builtins.toJSON entry.source}"
          )
        else
          entry.index == first.index
      ) indexedOptions;
    in
    if !builtins.isString prefix then
      throw "optionCatalogue.list: prefix must be a string"
    else
      map (entry: entry.option) uniqueOptions;

  describe =
    { allOptions, name }:
    let
      matchingOptions = lib.filter (option: optionName option == name) (
        checkedList "complete catalogue" allOptions
      );
    in
    if !builtins.isString name then
      throw "optionCatalogue.describe: name must be a string"
    else if matchingOptions == [ ] then
      null
    else if builtins.tail matchingOptions != [ ] then
      throw "optionCatalogue.describe: ambiguous option name ${builtins.toJSON name}"
    else
      checkedRecord (builtins.head matchingOptions);
in
{
  inherit project list describe;
}
