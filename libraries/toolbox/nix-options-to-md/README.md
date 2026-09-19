# Nix Options to Markdown

Renders a nested attrset of `mkOption` declarations into a Markdown option
catalog. The library only converts data; callers own discovery, namespacing, and
file output.

## Exports

| Attribute              | Description                                                                 |
| ---------------------- | --------------------------------------------------------------------------- |
| `allEntries`           | Flat list of every discovered option as `{ path, value }`                   |
| `markdownHeader`       | The table header row as a string                                            |
| `markdown`             | Render all entries under the default namespace                              |
| `markdownForNamespace` | Render entries under a custom namespace with optional header and exclusions |

## Boundary

This library does not:

- evaluate a module system
- discover files or import modules
- write to disk
- know about `myOptions`, `programs`, or any project namespace

Callers supply the option tree and decide where the result goes.

## Inputs

```nix
{
  lib, # nixpkgs.lib
  options, # attrset of mkOption declarations, possibly nested
  namespace ? "myOptions", # default namespace prefix for `markdown`
}
```

## Outputs

```nix
{
  allEntries = [ { path = [ "programs" "git" "enable" ]; value = ...; } ... ];
  markdownHeader = "| Option | Type | Default | Description |\n|--------|------|---------|-------------|";
  markdown = entries: "...";
  markdownForNamespace = { newNamespace, includeHeader ? true, exclude ? [] }: "...";
}
```

## Consumer example

```nix
let
  nixOptionsToMd = inputs.nix-batteries.batteriesLib.nixOptionsToMd;
  optionTree = {
    programs.git = {
      enable = lib.mkEnableOption "Git configuration";
      userName = lib.mkOption { type = lib.types.str; default = ""; };
    };
  };
in
nixOptionsToMd {
  inherit lib;
  options = optionTree;
  namespace = "myOptions.hm";
}.markdown nixOptionsToMd.allEntries
```

## REPL example

```sh
nix eval --impure --expr '
  let
    lib = (builtins.getFlake "nixpkgs").lib;
    nixOptionsToMd = import ./libraries/toolbox/nix-options-to-md { inherit lib; options = {}; };
  in
    builtins.attrNames nixOptionsToMd
' --json
```
