# lib - Flake Library Helpers

Small reusable Nix libraries live here. They should make module loading and
rendering easier to reason about, not hide business logic.

## What belongs here

| Directory | Owns |
|-----------|------|
| `modulette/` | Discovering header-validated Nix files |
| `guard-flake-input/` | Safely handling optional flake inputs |
| `themes/` | Theme data and theme option module |
| `decorators/` | Presentation helpers, currently command help legends |

