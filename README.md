<p align="center" style="font-size: 1.5em;"><strong>sidecar ❤️‍🔥</strong></p>

<p align="center"><strong>Nix flake Library Toolkit</strong></p>

<p align="center"><em>scan modules -> guard inputs -> render helpers -> share themes</em></p>

<br>

### What

A collection of reusable Nix libraries. They keep flake-level plumbing explicit without hiding the Nix module system.

### Where should I start

The sharpest piece is Modulon. It removes the old Nix pain point of manually
maintaining import lists as module trees grow. Drop a module into a scanned
directory and Modulon wires it into `imports`; add `@MODULON_SKIP` when a nearby
file should stay out of the module graph.

### Building blocks available

| Directory                            | Owns                                                               |
| ------------------------------------ | ------------------------------------------------------------------ |
| `libraries/decorators/`              | Presentation helpers                                               |
| `libraries/guard-flake-input/`       | Guardrails for the optional disabling of flake inputs              |
| `libraries/auto-discover/modulette/` | Discovering header-validated Nix modules                           |
| `libraries/auto-discover/modulon/`   | Plug-and-play module management framework for NixOS and Nix flakes |
| `libraries/themes/`                  | Theme option module and themes modules                             |
| `libraries/toolbox/`                 | Small reusable shell/runtime code generators                       |

### Flake structure

The flake uses [flake-parts](https://flake.parts/) and
[import-tree](https://github.com/denful/import-tree) for dendritic composition.
`flake.nix` declares inputs and loads `modules/`; every Nix file in that tree is
a flake-parts module. Import-tree recursively discovers `.nix` files and skips
paths containing `/_`.

- `modules/libraries/` owns the feature-level `sidecarLibs` exports.
- `modules/sidecar-libs.nix` declares their shared option contract and flake root.
- `modules/systems.nix`, `modules/checks.nix`, and `modules/formatter.nix` own
  the supported systems, fixture wiring, and formatter respectively.

`libraries/` retains the reusable implementations and their direct-import
paths. `fixtures/` retains test cases and data. Both trees sit outside automatic
flake-module discovery. Public helpers remain available through
`inputs.nix-sidecar.sidecarLibs`; consumers do not need flake-parts.

The public catalogue is a lazy attribute set with one definition per export.
Feature modules merge at the export-name boundary; individual helper values
retain their existing function and attribute-set contracts.

Checks and formatters cover `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and
`aarch64-darwin`. [Fixtures](fixtures/README.md) documents the validation boundary.
