![Dynamic NixOS Module Importer](.assets/images/modulon.png)

<p align="center" style="font-size: 1.5em;"><strong>Introducing Modulon 🦾</strong></p>

<p align="center"><em>Drop in a module. Let Modulon wire the import list.</em></p>

<p align="center">Works with NixOS • GNU/Linux distros & macOS via Home Manager</p>

<br>

## Why Modulon

Nix modules scale well, but import lists usually do not. Even today, many NixOS
and Home Manager configurations still rely on hand-maintained `imports = [ ... ]`
lists. Every new module needs a second edit somewhere else, and stale imports
become another piece of configuration drift.

Modulon returns a normal `{ imports = [ ... ]; }` module from one or more scan
roots. `discoveryMode = "modules"` includes regular `.nix` files after explicit
exclusions; roots must contain modules only, and one invalid import fails module
evaluation. `@MODULON_SKIP` excludes nearby support files.

The default `"heuristic"` mode preserves mixed-tree compatibility by counting
source-text patterns. It can miss valid plain modules and include non-modules
whose comments match. It is an approximate classifier, not module validation.
It remains until consumers migrate to module-only roots and a breaking release
can remove it. Both modes match exclusions below each root, independently of
the checkout's parent directories.

## Quick Start

1. **Use the library function:**

```nix
let
  moduleImporter = inputs.nix-batteries.batteriesLib.modulon;
in {
  nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
    modules = [
      ./configuration.nix
      (moduleImporter { dirs = [ ./modules ]; discoveryMode = "modules"; })
    ];
  };
}
```

The module system validates the selected NixOS, Home Manager, or shared modules.

<br>

## Table of Contents

- [How It Works](docs/01-HOW-IT-WORKS.md) — Module discovery process and pattern matching
- [Configuration](docs/02-CONFIGURATION.md) — Options reference and defaults
- [Excluding Modules](docs/03-EXCLUDING-MODULES.md) — `excludePaths` and `@MODULON_SKIP`
- [Extra Modules](docs/04-EXTRA-MODULES.md) — Include specific modules from excluded paths
- [Testing](docs/05-TESTING.md) — Running and debugging flake checks
- [Contributing](docs/06-CONTRIBUTING.md) — How to contribute

<br>

## License

Unless otherwise stated, everything in this repo is covered by the following copyright notice:

```plaintext
Modulon - An automated NixOS/Nix module importer.
Copyright (C) 2024-2026  Martín Cigorraga <cig0.github@gmail.com>

This program is free software: you can redistribute it and/or modify it
under the terms of the GNU Affero General Public License v3 or later, as
published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
```
