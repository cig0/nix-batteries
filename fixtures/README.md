# Fixtures

This directory contains lightweight fixture trees used by the flake checks.
They are intentionally small, deterministic examples of public `batteriesLib`
behavior. A fixture should prove one narrow library contract without depending
on consumer-specific configuration from another flake.

Current fixture directories:

- `consumer/` is a standalone flake using only a sidecar input. It exercises
  public helper calls, theme resolution, and a direct import through `flakeRoot`.
- `dynamic-aliases/` checks generic alias, legend, group, and name discovery.
- `git-repo-state/` executes literal labels, clean/dirty repositories, and failed
  lookups in Bash, Zsh, Dash, Fish, and Nushell; invalid identifiers fail at eval.
- `modulette/` checks header-validated data-module discovery in flat and
  directory modes, including a subdirectory that lacks the target file.
- `modulon/` checks both discovery modes, relocation beneath `tests`, exclusions,
  skip markers, and explicit extra modules.
- `nix-options-to-md/` checks missing types, literal expressions, Markdown control
  characters, and explicit rejection of unsupported defaults.
- `option-catalogue/` checks metadata projection, visibility, lazy queries,
  and invalid input through a direct library import. Its standalone entry point
  is separate from the flake check registry.
- `renderers/` checks generic Git-state helpers and help-legend output for
  POSIX, Fish, and Nushell, including runtime output for caller-authored
  payloads containing shell metacharacters, unset positional arguments, custom
  indentation, oversized titles, and exact leading-newline counts.
- `themes/` checks palette entry filtering, strict `#RRGGBB` validation, and
  theme resolution through fixture-specific source trees.

`fixtures/default.nix` aggregates the checks returned by focused fixture
modules. [`flake.nix`](../flake.nix) passes `batteriesLib`, the shared nixpkgs
`lib`, and each system's package set into that aggregator. The flake also
evaluates the consumer's `smoke` output with the public flake as its input. A
separate Nix invocation verifies input resolution through the consumer's own
entry point:

```shell
nix eval ./fixtures/consumer#smoke --json --no-write-lock-file
```

The consumer resolves `sidecar` from the repository root and reuses its locked
dependencies. Its transient lock graph is not saved in the fixture tree.

## Running checks

```sh
# Evaluate the registered checks for every supported system.
nix flake check --all-systems --no-build --no-write-lock-file

# Build and execute registered checks for the current system.
nix flake check --no-write-lock-file

# Run the option-catalogue fixture, which has no public flake export yet.
nix eval --impure --json --file fixtures/option-catalogue/check.nix --no-write-lock-file

# Regenerate the help example in memory and compare the committed text/SVG.
python3 assets/tools/render-help-example.py --check
```

[CI](../.github/workflows/ci.yml) runs native checks, the standalone consumer,
option-catalogue, and example checks on Linux x86_64 and macOS ARM64. The Linux
job also evaluates all four supported systems. Evaluation alone does not run a
system's runtime fixtures.

## Fixture Guidelines

Keep fixture files focused:

1. Use the smallest file tree that proves the behavior.
2. Prefer obvious names such as `valid.nix`, `skipped.nix`, or
   `not-a-file.nix`.
3. Avoid generated data, host paths, network access, timestamps, and other
   non-deterministic inputs.
4. Keep fixtures tied to public `self.batteriesLib` behavior, not private
   implementation details.
5. Run the affected fixture and the checks above after changes.
