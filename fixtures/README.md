# Fixtures

This directory contains lightweight fixture trees used by `flake.nix` checks.
They are intentionally small, deterministic examples of public `igniteLibs`
behavior. A fixture should prove one narrow library contract without depending
on consumer-specific configuration from another flake.

Current fixture directories:

- `dynamic-aliases/` checks generic alias, legend, group, and name discovery.
- `modulette/` checks header-validated data-module discovery.
- `modulon/` checks Nix module auto-discovery, skip markers, and explicit extra
  modules.

The check wiring lives in the repository root `flake.nix` under `checks`. When
you add or change a fixture, update the matching check assertions at the same
time so the fixture continues to document a real behavior boundary.

## Fixture Guidelines

Keep fixture files focused:

1. Use the smallest file tree that proves the behavior.
2. Prefer obvious names such as `valid.nix`, `skipped.nix`, or `ignored.nix`.
3. Avoid generated data, host paths, network access, timestamps, and other
   non-deterministic inputs.
4. Keep fixtures tied to public `self.igniteLibs` behavior, not private
   implementation details.
5. Run the focused flake check after changes:

```shell
nix flake check --all-systems --no-build
```
