# Dynamic Aliases

Turn discovered names into shell alias data, help legend data, and optional
help-section groups. The library creates data only. Consumers decide how to
discover names, how commands should look, and how aliases are rendered by POSIX,
Fish, Nushell, Home Manager, or another shell system.

## Exports

| Attribute | Description |
|---|---|
| `mk` | Build alias, legend, and group data from names or entries |
| `discoverNixFileNames` | Return flat `.nix` basenames from a directory |

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

## From Zero To Flake Shell Shortcuts

This walkthrough builds the same shape of data used by `nix-ignition`: `nd-*`
shortcuts for development shells and `ns-*` shortcuts for package-only shells.

### 1. Create flake shell files

Start with two files in your flake:

```text
shells/devShells/rust.nix
shells/packages/security.nix
```

The files can be discovered by whatever mechanism your project already uses.
For example, `nix-ignition` uses Modulette for flake outputs, but alias
generation only needs the file names.

### 2. Import the library

Inside your flake or module:

```nix
let
  dynamicAliases = inputs.nix-ignite.igniteLibs.dynamicAliases;
  flakeSrcPath = "/home/me/work/my-flake";
in
...
```

Use a real source path when aliases should work outside the flake directory.
Use `"."` when the aliases should be relative to the current directory.

### 3. Discover the names

```nix
let
  devShellNames = dynamicAliases.discoverNixFileNames {
    directory = ./shells/devShells;
  };

  packageNames = dynamicAliases.discoverNixFileNames {
    directory = ./shells/packages;
  };
in
...
```

For the two files above, the values are:

```nix
devShellNames = [ "rust" ];
packageNames = [ "security" ];
```

### 4. Generate development-shell aliases

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
  nd-rust = "nix develop /home/me/work/my-flake#rust";
};

devShellDynamicAliases.legend = {
  nd-rust = "nix develop .#rust";
};

devShellDynamicAliases.group = {
  name = "Development Shells";
  cmds = [ "nd-rust" ];
};
```

### 5. Generate package-shell aliases

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
  ns-security = "nix shell /home/me/work/my-flake#security";
};

packageDynamicAliases.legend = {
  ns-security = "nix shell .#security";
};

packageDynamicAliases.group = {
  name = "Ephemeral Packages";
  cmds = [ "ns-security" ];
};
```

### 6. Feed aliases into shell config

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

### 7. Feed legend and group data into help

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
