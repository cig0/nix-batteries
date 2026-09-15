# Modulon Fixture

This fixture proves that `sidecarLibs.modulon` builds an `imports` list from a
module directory, ignores files marked with `@MODULON_SKIP`, and preserves
modules passed through `extraModules`.

The `modulon-fixture` check in `fixtures/default.nix` (wired via `modules/checks.nix`) builds the fixture with:

```nix
sidecarLibs.modulon {
  dirs = [ ./modulon/modules ];
  extraModules = [ ./modulon/extra-module.nix ];
}
```

It then asserts that:

- `modules/valid.nix` is discovered.
- `extra-module.nix` is included through `extraModules`.
- `modules/skipped.nix` is not included because it contains `@MODULON_SKIP`.

## Layout

- `modules/valid.nix` is a minimal valid Nix module and should be discovered.
- `modules/skipped.nix` is a valid-looking module with `@MODULON_SKIP` and
  should be ignored.
- `extra-module.nix` lives outside the scanned directory and should still be
  included because the check passes it explicitly as an extra module.

## Extending This Fixture

Use this path when changing Modulon discovery behavior:

1. Decide which behavior you need to prove: discovery, exclusion,
   `@MODULON_SKIP`, recursion, `extraModules`, or another public argument.
2. Add the smallest possible `.nix` module under `modules/`, or next to
   `extra-module.nix` if it must be supplied explicitly.
3. Make discovered files look like real Nix modules. They should include at
   least two of Modulon's module-detection patterns, such as `{ lib, ... }:`,
   `options.`, or `config.`.
4. Put `# @MODULON_SKIP` in files that should remain near the fixture without
   appearing in the generated `imports` list.
5. Update the `modulon-fixture` assertions in `fixtures/default.nix` so they prove
   exactly which paths are included or excluded.
6. Run:

```shell
nix flake check --all-systems --no-build
```

For the public API contract and discovery rules, see `../../libraries/auto-discover/modulon/README.md`
and `../../libraries/auto-discover/modulon/docs/`.
