# Fixtures

This directory contains lightweight fixture trees used by the flake checks.
They are intentionally small, deterministic examples of public `batteriesLib`
behavior. A fixture should prove one narrow library contract without depending
on consumer-specific configuration from another flake.

Current fixture directories:

- `consumer/` is a standalone flake using only a sidecar input. It exercises
  public helper calls, theme resolution, and a direct import through `flakeRoot`.
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
modules. [`flake.nix`](../flake.nix) passes `batteriesLib`, the shared nixpkgs
`lib`, and each system's package set into that aggregator. The flake also
evaluates the consumer's `smoke` output with the public flake as its input. A separate Nix invocation verifies input resolution through
the consumer's own entry point:

```shell
nix eval ./fixtures/consumer#smoke --json --no-write-lock-file
```

The consumer resolves `sidecar` from the repository root and reuses its locked
dependencies. Its transient lock graph is not saved in the fixture tree.

## Fixture Guidelines

Keep fixture files focused:

1. Use the smallest file tree that proves the behavior.
2. Prefer obvious names such as `valid.nix`, `skipped.nix`, or
   `not-a-file.nix`.
3. Avoid generated data, host paths, network access, timestamps, and other
   non-deterministic inputs.
4. Keep fixtures tied to public `self.batteriesLib` behavior, not private
   implementation details.
5. Run the focused flake check after changes:

```shell
nix flake check --all-systems --no-build
```
