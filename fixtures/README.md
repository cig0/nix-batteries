# Fixtures

This directory contains lightweight fixture trees used by `flake.nix` checks.
They are intentionally small, deterministic examples of public `nitroLibs`
behavior. A fixture should prove one narrow library contract without depending
on consumer-specific configuration from another flake.

Current fixture directories:

- `dynamic-aliases/` checks generic alias, legend, group, and name discovery.
- `modulette/` checks header-validated data-module discovery.
- `modulon/` checks Nix module auto-discovery, skip markers, and explicit extra
  modules.
- `nix-options-to-md/` checks option declarations rendered as Markdown rows.
- `renderers/` checks generic Git-state helpers and help-legend output for
  POSIX, Fish, and Nushell.
- `themes/` checks palette entry filtering, strict `#RRGGBB` validation, and
  theme resolution through fixture-specific source trees.

`fixtures/default.nix` aggregates the checks returned by focused fixture
modules. The repository root `flake.nix` only passes `nitroLibs`, `lib`, and the
system package set into that aggregator.

## Fixture Guidelines

Keep fixture files focused:

1. Use the smallest file tree that proves the behavior.
2. Prefer obvious names such as `valid.nix`, `skipped.nix`, or
   `not-a-file.nix`.
3. Avoid generated data, host paths, network access, timestamps, and other
   non-deterministic inputs.
4. Keep fixtures tied to public `self.nitroLibs` behavior, not private
   implementation details.
5. Run the focused flake check after changes:

```shell
nix flake check --all-systems --no-build
```
