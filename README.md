# nix-ignite - Flake Library Toolkit

```text
          _                 _             _ _
  _ __   (_)_  __     ___  (_) __ _ _ __ (_) |_ ___
 | '_ \  | \ \/ /____/ _ \ | |/ _` | '_ \| | __/ _ \
 | | | | | |>  <____|  __/ | | (_| | | | | | ||  __/
 |_| |_| |_/_/\_\    \___| |_|\__, |_| |_|_|\__\___|
                              |___/

      scan modules -> guard inputs -> render helpers -> share themes
```

Small reusable Nix libraries live here. They should make module loading and
rendering easier to reason about, not hide business logic.

## What belongs here

| Directory | Owns |
|-----------|------|
| `modulette/` | Discovering header-validated Nix files |
| `guard-flake-input/` | Safely handling optional flake inputs |
| `themes/` | Theme data and theme option module |
| `decorators/` | Presentation helpers, currently command help legends |
| `toolbox/` | Small reusable shell/runtime code generators |
