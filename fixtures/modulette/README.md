# Modulette Fixture

This fixture proves that `igniteLibs.modulette.discoverModules` imports only
files whose first line matches the requested header, passes `args` through to the
imported module, and returns an attrset keyed by filename without `.nix`.

The root `flake.nix` check scans `modules/` with:

```nix
self.igniteLibs.modulette.discoverModules {
  directory = ./fixtures/modulette/modules;
  headerText = "# Modulette fixture module. Do not remove this header.";
  args = {
    value = "loaded";
  };
}
```

It then asserts that the discovered attrset contains only `alpha` and that
`alpha.value == "loaded"`.

## Layout

- `modules/alpha.nix` has the expected first-line header and should be loaded.
- `modules/ignored.nix` has a different first-line header and should be ignored.

## Extending This Fixture

Use this path when changing Modulette discovery behavior:

1. Add the smallest possible `.nix` file under `modules/` that demonstrates the
   behavior.
2. Give loadable files the exact header used by the check:
   `# Modulette fixture module. Do not remove this header.`
3. Leave intentionally ignored files without that exact first line.
4. Return a tiny attrset from the fixture module. If the behavior needs input,
   read it from the `args` passed in `flake.nix`.
5. Update the `modulette-fixture` assertions in the root `flake.nix` so they
   prove the new expectation.
6. Run:

```shell
nix flake check --all-systems --no-build
```

For the public API contract and broader examples, see `../../modulette/README.md`.

