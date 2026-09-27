/*
  Nix option declaration → Markdown table renderer.

  Walks a nested attrset of `mkOption` / `mkEnableOption` declarations and emits
  rows suitable for an option catalog. It does not evaluate a module system or
  read files; callers supply the option tree.
*/
{
  lib, # caller args → nixpkgs.lib
  options, # caller args → option declaration tree
  namespace ? "myOptions", # caller args → rendered option prefix
}:

let
  inherit (lib)
    any
    concatStringsSep
    filter
    length
    mapAttrsToList
    optionalString
    replaceStrings
    take
    ;

  isOption = x: builtins.isAttrs x && x._type or null == "option";

  walk =
    prefix: value:
    if isOption value then
      [
        {
          path = prefix;
          inherit value;
        }
      ]
    else if builtins.isAttrs value then
      lib.concatLists (mapAttrsToList (name: child: walk (prefix ++ [ name ]) child) value)
    else
      [ ];

  pathMatchesPrefix =
    prefix: path: length prefix <= length path && take (length prefix) path == prefix;

  filterEntries =
    exclude: entries:
    if exclude == [ ] then
      entries
    else
      filter (
        entry:
        !any (
          excludeSpec:
          let
            spec = if builtins.isList excludeSpec then excludeSpec else lib.splitString "." excludeSpec;
          in
          pathMatchesPrefix spec entry.path
        ) exclude
      ) entries;

  # Preserve caller Markdown, but keep every value inside one GFM table cell.
  escapeCell = replaceStrings [ "\r" "\n" "\t" "|" ] [ " " " " " " "\\|" ];
  sanitizeDescription = text: escapeCell (replaceStrings [ "  " ] [ " " ] (lib.trim text));

  literalText =
    value:
    if builtins.isString value then
      value
    else if
      builtins.isAttrs value
      && builtins.elem (value._type or "") [
        "literalExpression"
        "literalMD"
      ]
      && builtins.isString (value.text or null)
    then
      value.text
    else
      throw "nixOptionsToMd: expected a string or nixpkgs literalExpression/literalMD record";

  # Backticks cannot be backslash-escaped inside code spans. A longer delimiter
  # and boundary padding preserve embedded runs and leading/trailing backticks.
  codeSpan =
    text:
    let
      runs = builtins.filter builtins.isList (builtins.split "(`+)" text);
      longestRun = builtins.foldl' (
        maximum: run: lib.max maximum (builtins.stringLength (builtins.head run))
      ) 0 runs;
      delimiter = lib.concatStrings (builtins.genList (_: "`") (longestRun + 1));
      padding =
        if
          lib.hasPrefix "`" text || lib.hasSuffix "`" text || lib.hasPrefix " " text || lib.hasSuffix " " text
        then
          " "
        else
          "";
    in
    "${delimiter}${padding}${escapeCell text}${padding}${delimiter}";

  isJsonValue =
    value:
    if builtins.isList value then
      builtins.all isJsonValue value
    else if builtins.isAttrs value then
      # toJSON serializes store-backed values through outPath, without walking
      # derivation builders or their function-valued metadata.
      if value ? outPath then
        isJsonValue value.outPath
      else
        builtins.all isJsonValue (builtins.attrValues value)
    else
      builtins.elem (builtins.typeOf value) [
        "null"
        "bool"
        "int"
        "float"
        "string"
        "path"
      ];

  typeDescription =
    option:
    if !(option ? type) || option.type == null then
      "unknown"
    else if option.type ? description then
      option.type.description
    else if option.type ? name then
      option.type.name
    else
      "unknown";

  # Literal defaults are serialized with builtins.toJSON: a string keeps its
  # quotes (`"fast"`) and structured values render in JSON syntax.
  defaultValue =
    option:
    if option ? defaultText then
      let
        text = literalText option.defaultText;
      in
      if lib.trim text == "" then
        "(expression)"
      else if builtins.isAttrs option.defaultText && option.defaultText._type == "literalExpression" then
        codeSpan text
      else
        sanitizeDescription text
    else if option ? default then
      let
        serialized =
          if isJsonValue option.default then
            builtins.toJSON option.default
          else
            throw "nixOptionsToMd: unsupported default; provide defaultText for functions or other non-JSON values";
      in
      codeSpan serialized
    else
      "—";

  descriptionValue =
    option:
    optionalString (option ? description) (sanitizeDescription (literalText option.description));

  pathString = path: concatStringsSep "." path;

  formatRow =
    targetNamespace:
    { path, value }:
    "| ${codeSpan "${targetNamespace}.${pathString path}"} | ${sanitizeDescription (typeDescription value)} | ${defaultValue value} | ${descriptionValue value} |";

  allEntries = walk [ ] options;

  markdownHeader = ''
    | Option | Type | Default | Description |
    |--------|------|---------|-------------|'';
in
{
  inherit allEntries markdownHeader;

  markdown =
    entries: concatStringsSep "\n" ([ markdownHeader ] ++ (map (formatRow namespace) entries));

  markdownForNamespace =
    {
      newNamespace, # caller args → rendered option prefix
      includeHeader ? true, # caller args → table header toggle
      exclude ? [ ], # caller args → path prefixes to omit
    }:
    let
      entries = filterEntries exclude allEntries;
      rows = map (formatRow newNamespace) entries;
    in
    concatStringsSep "\n" (if includeHeader then [ markdownHeader ] ++ rows else rows);
}
