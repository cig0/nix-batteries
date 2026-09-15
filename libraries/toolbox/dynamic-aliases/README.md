# Dynamic Aliases

Turn discovered names into shell alias data, help legend data, and optional
help-section groups. The library creates data only. Consumers decide how to
discover names, how commands should look, and how aliases are rendered by POSIX,
Fish, Nushell, Home Manager, or another shell system.

## Exports

| Attribute              | Description                                               |
| ---------------------- | --------------------------------------------------------- |
| `mk`                   | Build alias, legend, and group data from names or entries |
| `discoverNixFileNames` | Return flat `.nix` basenames from a directory             |

## Boundary

`dynamicAliases` does not know about flakes, `nix develop`, `nix shell`, shell
syntax, colors, help screens, Home Manager, or NixOS. It only maps input names
to output attrsets.

Consumers own:

- where names come from
- alias names
- command values
- help descriptions
- shell rendering
- whether a returned group is shown in a help screen

## `mk` Inputs

`mk` accepts either `names` or `entries`:

- `names`: list of names; every callback receives `null` as the entry value.
- `entries`: attrset keyed by name; callbacks receive each keyed value.

Both modes require `nameFor` and `valueFor`. `legendFor` defaults to `valueFor`,
and `groupName` defaults to `null`. Unknown extra attributes are ignored for
backwards compatibility with callers that carry local metadata beside the
documented arguments.

## From Zero To Flake Shell Shortcuts

This walkthrough builds the same shape of data used by `nix-v8`: `nd-*`
shortcuts for development shells and `ns-*` shortcuts for package-only shells.

### 1. Pick a layout

Pick whichever layout your flake already uses — both are supported. You only
need to be consistent within one directory:

```text
# Directory layout: one subdirectory per shell, with default.nix inside.
shells/devShell/rust/default.nix
shells/devShell/python/default.nix
shells/package/security/default.nix
shells/package/cloud-infra-tools/default.nix

# Flat layout: one .nix file per shell, all at the top level.
shells/devShell/rust.nix
shells/devShell/python.nix
shells/package/security.nix
shells/package/cloud-infra-tools.nix
```

Each file is a self-contained `mkShell` or `buildEnv`. The walkthrough below
uses the directory layout for both development shells and packages — the same
shape nix-v8 uses, since each shell gets an adjacent `README.md` and a
stable entry point.

### 2. Create a shell file

For the directory layout, put a `default.nix` inside each subdirectory. The
filename does not matter for discovery — only the directory basename does:

```nix
# shells/devShell/rust/default.nix
{ pkgs }:
pkgs.mkShell {
  name = "rust";
  packages = [ pkgs.cargo pkgs.rustc ];
}
```

For the flat layout, drop the wrapping directory:

```nix
# shells/devShell/rust.nix
{ pkgs }:
pkgs.mkShell {
  name = "rust";
  packages = [ pkgs.cargo pkgs.rustc ];
}
```

Alias generation only needs the file or directory names, so how your flake
discovers shells for `nix develop` (Modulette, hand-maintained lists, or
something else) does not affect the rest of this walkthrough.

### 3. Import the library

Inside your flake or module:

```nix
let
  dynamicAliases = inputs.nix-batteries.sidecarLibs.dynamicAliases;
  flakeSrcPath = "/home/me/work/my-flake";
in
...
```

Use a real source path when aliases should work outside the flake directory.
Use `"."` when the aliases should be relative to the current directory.

### 4. Discover the names

Use the helper that matches your layout. `discoverNixFileNames` reads top-level
`.nix` files in a directory; for the directory layout, read the directory and
filter to subdirectory basenames.

```nix
# Directory layout: enumerate subdirectory basenames under shells/devShell/.
devShellNames =
  let
    entries = builtins.readDir (self.outPath + "/shells/devShell");
    isDir = name: entries.${name} == "directory";
  in
  builtins.filter isDir (builtins.attrNames entries);

# Flat layout: top-level .nix files under shells/devShell/.
# Use discoverNixFileNames for this shape.
devShellNames = dynamicAliases.discoverNixFileNames {
  directory = ./shells/devShell;
};

# Directory layout: enumerate subdirectory basenames under shells/package/.
packageNames =
  let
    entries = builtins.readDir (self.outPath + "/shells/package");
    isDir = name: entries.${name} == "directory";
  in
  builtins.filter isDir (builtins.attrNames entries);

# Flat layout: top-level .nix files under shells/package/.
# Use discoverNixFileNames for this shape.
packageNames = dynamicAliases.discoverNixFileNames {
  directory = ./shells/package;
};
```

For the directory-layout example in step 1, `devShellNames` evaluates to
`[ "python" "rust" ]` and `packageNames` evaluates to
`[ "cloud-infra-tools" "security" ]`. For the flat-layout example, the same
two `devShellNames` and `packageNames` calls produce the same list of strings,
just from a different on-disk shape.

### 5. Generate development-shell aliases

```nix
let
  devShellDynamicAliases = dynamicAliases.mk {
    names = devShellNames;
    nameFor = name: _: "nd-${name}";
    valueFor = name: _: "nix develop ${flakeSrcPath}#${name}";
    legendFor = name: _: "nix develop .#${name}";
    groupName = "Development Shells";
  };
in
...
```

Expected data:

```nix
devShellDynamicAliases.aliases = {
  nd-python = "nix develop /home/me/work/my-flake#python";
  nd-rust = "nix develop /home/me/work/my-flake#rust";
};

devShellDynamicAliases.legend = {
  nd-python = "nix develop .#python";
  nd-rust = "nix develop .#rust";
};

devShellDynamicAliases.group = {
  name = "Development Shells";
  cmds = [
    "nd-python"
    "nd-rust"
  ];
};
```

### 6. Generate package-shell aliases

```nix
let
  packageDynamicAliases = dynamicAliases.mk {
    names = packageNames;
    nameFor = name: _: "ns-${name}";
    valueFor = name: _: "nix shell ${flakeSrcPath}#${name}";
    legendFor = name: _: "nix shell .#${name}";
    groupName = "Ephemeral Packages";
  };
in
...
```

Expected data:

```nix
packageDynamicAliases.aliases = {
  ns-cloud-infra-tools = "nix shell /home/me/work/my-flake#cloud-infra-tools";
  ns-security = "nix shell /home/me/work/my-flake#security";
};

packageDynamicAliases.legend = {
  ns-cloud-infra-tools = "nix shell .#cloud-infra-tools";
  ns-security = "nix shell .#security";
};

packageDynamicAliases.group = {
  name = "Ephemeral Packages";
  cmds = [
    "ns-cloud-infra-tools"
    "ns-security"
  ];
};
```

### 7. Feed aliases into shell config

For POSIX shells or Nushell-style alias attrsets:

```nix
aliases =
  devShellDynamicAliases.aliases
  // packageDynamicAliases.aliases;
```

For Fish, the same data can be used as abbreviations:

```nix
abbrs =
  devShellDynamicAliases.aliases
  // packageDynamicAliases.aliases;
```

The library does not render `alias nd-rust=...`, `abbr nd-rust ...`, or any
other shell syntax. That belongs to the consumer.

### 8. Feed legend and group data into help

```nix
let
  legend =
    baseLegend
    // devShellDynamicAliases.legend
    // packageDynamicAliases.legend;

  flakeGroups = builtins.filter (group: group.cmds != [ ]) [
    devShellDynamicAliases.group
    packageDynamicAliases.group
  ];
in
...
```

Your help renderer can now show `nd-rust` and `ns-security`, while the
descriptions explain the underlying flake commands.

## Other Real Use Cases

Project task aliases can use the same library without any flake-shell policy:

```nix
let
  projectTasks = dynamicAliases.mk {
    names = [
      "fmt"
      "test"
      "lint"
    ];
    nameFor = name: _: "p-${name}";
    valueFor = name: _: "just ${name}";
    legendFor = name: _: "Run `just ${name}`";
    groupName = "Project Tasks";
  };
in
{
  aliases = projectTasks.aliases;
  legend = projectTasks.legend;
  helpGroups = [ projectTasks.group ];
}
```

Expected aliases:

```nix
{
  p-fmt = "just fmt";
  p-test = "just test";
  p-lint = "just lint";
}
```

When each item needs metadata, pass `entries` instead of `names`:

```nix
let
  devShells = dynamicAliases.mk {
    entries = {
      rust = {
        command = "nix develop";
        display = "Rust development shell";
      };
    };
    nameFor = name: _: "nd-${name}";
    valueFor = name: entry: "${entry.command} .#${name}";
    legendFor = _: entry: entry.display;
  };
in
devShells.legend
```

Expected legend:

```nix
{
  nd-rust = "Rust development shell";
}
```

## Duplicate Protection

Generated alias names must be unique. This throws:

```nix
dynamicAliases.mk {
  names = [
    "fmt"
    "format"
  ];
  nameFor = _: _: "fmt";
  valueFor = name: _: "just ${name}";
}
```

The error points at the duplicate generated alias name so consumers can fix
their naming policy.
