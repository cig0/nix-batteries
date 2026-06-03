![A Nix flake toolkit with reusable building blocks. Home of Modulon.](.assets/images/nix-ignite.png)

<p align="center" style="font-size: 1.5em;"><strong>Ignite 🔥</strong></p>

<p align="center">Nix flake Library Toolkit</p>

<p align="center"><em>scan modules -> guard inputs -> render helpers -> share themes</em></p>

<br>

### What

Small reusable Nix libraries live here. They keep flake-level plumbing explicit:
discover modules, guard optional inputs, render shell helpers, and share theme
data without hiding the Nix module system.

### Why

The sharpest piece is Modulon. It removes the old Nix pain point of manually
maintaining import lists as module trees grow. Drop a module into a scanned
directory and Modulon wires it into `imports`; add `@MODULON_SKIP` when a nearby
file should stay out of the module graph.

### Building blocks available

| Directory | Owns |
|-----------|------|
| `decorators/` | Presentation helpers, currently command help legends |
| `guard-flake-input/` | Safely handling optional flake inputs |
| `modulette/` | Discovering header-validated Nix files |
| `modulon/` | Plug-and-play module management framework for NixOS and Nix flakes |
| `themes/` | Theme data and theme option module |
| `toolbox/` | Small reusable shell/runtime code generators |
