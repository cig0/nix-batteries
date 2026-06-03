# nix-ignite - Flake Library Toolkit

```text
          _           _             _ _
  _ __   (_)_  __    (_) __ _ _ __ (_) |_ ___
 | '_ \  | \ \/ /____| |/ _` | '_ \| | __/ _ \
 | | | | | |>  <____|| | (_| | | | | | ||  __/
 |_| |_| |_/_/\_\    |_|\__, |_| |_|_|\__\___|
                         |___/

      scan modules -> guard inputs -> render helpers -> share themes
```

Small reusable Nix libraries live here. They keep flake-level plumbing explicit:
discover modules, guard optional inputs, render shell helpers, and share theme
data without hiding the Nix module system.

## Why this exists

The sharpest piece is Modulon. It removes the old Nix pain point of manually
maintaining import lists as module trees grow. Drop a module into a scanned
directory and Modulon wires it into `imports`; add `@MODULON_SKIP` when a nearby
file should stay out of the module graph.

## What belongs here

| Directory | Owns |
|-----------|------|
| `decorators/` | Presentation helpers, currently command help legends |
| `guard-flake-input/` | Safely handling optional flake inputs |
| `modulette/` | Discovering header-validated Nix files |
| `modulon/` | Plug-and-play module management framework for NixOS and Nix flakes |
| `themes/` | Theme data and theme option module |
| `toolbox/` | Small reusable shell/runtime code generators |
