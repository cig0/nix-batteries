<p align="center" style="font-size: 1.5em;"><strong>nix-batteries ❤️‍🔥</strong></p>

<p align="center"><strong>Nix flake Library Toolkit</strong></p>

<p align="center"><em>scan modules -> guard inputs -> render helpers -> share themes</em></p>

<br>

### What

Reusable Nix libraries for module discovery, optional flake inputs, shell help,
and terminal themes. Pick the helpers you need; they work with the ordinary Nix
module system and do not require a configuration framework.

### Where should I start

Add the flake to your inputs:

```nix
inputs.nix-batteries.url = "github:cig0/nix-batteries";
```

Where your consumer has access to `inputs`, helpers are available through
`inputs.nix-batteries.batteriesLib`. For example, this builds alias data:

```nix
let
  batteries = inputs.nix-batteries.batteriesLib;
in
batteries.dynamicAliases.mk {
  names = [ "fmt" "test" ];
  nameFor = name: _: "p-${name}";
  valueFor = name: _: "just ${name}";
}
```

The result includes `aliases.p-fmt = "just fmt"` and
`aliases.p-test = "just test"`. Your consumer decides how to install those
aliases in a shell.

For automatic module imports, start with [Modulon](libraries/auto-discover/modulon/README.md).
It returns a normal `{ imports = [ ... ]; }` module from selected directories.
[Modulette](libraries/auto-discover/modulette/README.md) instead imports named data
modules into an attribute set, with optional header checks.

### Building blocks available

| Library | Use it for |
| --- | --- |
| [Modulon](libraries/auto-discover/modulon/README.md) | Recursive module discovery and import lists |
| [Modulette](libraries/auto-discover/modulette/README.md) | Named data modules from files or subdirectories |
| [Guard flake input](libraries/guard-flake-input/README.md) | Explicit fallbacks when an optional input is absent |
| [Help legend](libraries/decorators/help-legend/README.md) | Command help for POSIX shells, Fish, and Nushell |
| [Themes](libraries/themes/README.md) | Raw colors, ANSI styles, and a theme option module |
| [Dynamic aliases](libraries/toolbox/dynamic-aliases/README.md) | Alias, legend, and help-group data |
| [Git repository state](libraries/toolbox/git-repo-state/README.md) | Runtime revision and dirty-state helpers |
| [Nix options to Markdown](libraries/toolbox/nix-options-to-md/README.md) | Markdown tables from option declarations |

[Option catalogue](libraries/toolbox/option-catalogue/README.md) is available by
direct import for querying evaluated option metadata. It is not yet a
`batteriesLib` export.

### Flake structure

`flake.nix` has one input, `nixpkgs`, and exposes `batteriesLib`, `checks`, and
`formatter`. Each public helper points to its implementation under `libraries/`;
its documented direct-import path also remains available.

Supported systems are `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and
`aarch64-darwin`.

### Checks

[![CI](https://github.com/cig0/nix-batteries/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/cig0/nix-batteries/actions/workflows/ci.yml)
[![License: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue)](LICENSE)

From the repository root:

```sh
# Evaluate checks for all four systems.
nix flake check --all-systems --no-build --no-write-lock-file

# Build and run checks for your current system.
nix flake check --no-write-lock-file
```

[CI](.github/workflows/ci.yml) runs on pull requests and pushes to `main`.
It runs native checks on Linux x86_64 and macOS ARM64; the other two systems
receive evaluation coverage. See [fixtures](fixtures/README.md) for the consumer,
option-catalogue, and generated-example checks.
