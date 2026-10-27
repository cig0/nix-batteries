<p align="center" style="font-size: 1.5em;"><strong>nix-batteries ❤️‍🔥</strong></p>

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

`flake.nix` takes one input (`nixpkgs`) and produces three outputs directly,
with no framework inputs. `batteriesLib` is a static attribute set mapping each
public export onto its implementation under `libraries/`; `checks` and
`formatter` fan out per supported system through a small `forSystems` helper.

`libraries/` retains the reusable implementations and their direct-import
paths. `fixtures/` retains test cases and data. Public helpers remain available
through `inputs.nix-batteries.batteriesLib`.

The public catalogue is a plain lazy attribute set with one definition per
export. Individual helper values retain their existing function and
attribute-set contracts.

Checks and formatters cover `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, and
`aarch64-darwin`. [Fixtures](fixtures/README.md) documents the validation boundary.

[Public backports and release privacy checks](assets/docs/PUBLIC-BACKPORTS.md)
describes the patch-transfer and release boundaries.
