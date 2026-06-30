![A Nix flake toolkit with reusable building blocks. Home of Modulon.](assets/images/nix-fuel.png)

<p align="center" style="font-size: 1.5em;"><strong>fuel ❤️‍🔥</strong></p>

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

| Directory | Owns |
|-----------|------|
| `libraries/decorators/` | Presentation helpers |
| `libraries/guard-flake-input/` | Guardrails for the optional disabling of flake inputs |
| `libraries/auto-discover/modulette/` | Discovering header-validated Nix modules |
| `libraries/auto-discover/modulon/` | Plug-and-play module management framework for NixOS and Nix flakes |
| `libraries/themes/` | Theme option module and themes modules |
| `libraries/toolbox/` | Small reusable shell/runtime code generators |
