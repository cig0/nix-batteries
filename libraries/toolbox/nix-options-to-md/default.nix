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

  sanitizeDescription = text: replaceStrings [ "\n" "  " ] [ " " " " ] (lib.trim text);

  typeDescription =
    option:
    if option.type ? description then
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
        text = sanitizeDescription option.defaultText;
      in
      if text == "" then "(expression)" else "${text}"
    else if option ? default then
      let
        s = builtins.toJSON option.default;
      in
      if s == "\"\"" then "`\"\"`" else "`${s}`"
    else
      "—";

  descriptionValue =
    option: optionalString (option ? description) (sanitizeDescription option.description);

  pathString = path: concatStringsSep "." path;

  formatRow =
    targetNamespace:
    { path, value }:
    "| `${targetNamespace}.${pathString path}` | ${typeDescription value} | ${defaultValue value} | ${descriptionValue value} |";

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
