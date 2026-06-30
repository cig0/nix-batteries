# Modulette Fixtures

This directory contains focused fixtures for both scanning modes of `fuelLibs.modulette.discoverModules`.

## Flat mode fixture

The `modules/` fixture proves that discovery imports only files whose first line matches the requested header, passes `args` through to the imported module, and returns an attrset keyed by filename without `.nix`.

The root `flake.nix` check scans `modules/` with:

```nix
self.fuelLibs.modulette.discoverModules {
  mode = "flat";
  directory = ./fixtures/modulette/modules;
  headerText = "# Modulette fixture module. Do not remove this header.";
  args = {
    value = "loaded";
  };
}
```

It then asserts that the discovered attrset contains only `alpha` and that `alpha.value == "loaded"`.

### Layout

- `modules/alpha.nix` has the expected first-line header and should be loaded.
- `modules/ignored.nix` has a different first-line header and should be ignored.

## Directory mode fixture

The `hosts/` fixture proves that discovery can scan subdirectories, import a target file from each one, and return an attrset keyed by directory name.

The root `flake.nix` check scans `hosts/` with:

```nix
self.fuelLibs.modulette.discoverModules {
  mode = "directory";
  directory = ./fixtures/modulette/hosts;
  targetFile = "host.nix";
  headerText = "# Modulette fixture module. Do not remove this header.";
  args = {
    value = "loaded";
  };
}
```

It then asserts that the discovered attrset contains `alpha` and `beta`, each with the expected metadata.

### Layout

- `hosts/alpha/host.nix` has the expected header and should be loaded as `alpha`.
- `hosts/beta/host.nix` has the expected header and should be loaded as `beta`.

## Extending These Fixtures

Use this path when changing Modulette discovery behavior:

1. Add the smallest possible `.nix` file or directory that demonstrates the behavior.
2. Give loadable files the exact header used by the check:
   `# Modulette fixture module. Do not remove this header.`
3. Leave intentionally ignored files without that exact first line.
4. Return a tiny attrset from the fixture module. If the behavior needs input, read it from the `args` passed in `flake.nix`.
5. Update the relevant `modulette-fixture` or `modulette-directory-fixture` assertions in the root `flake.nix` so they prove the new expectation.
6. Run:

```shell
nix flake check --all-systems --no-build
```

For the public API contract and broader examples, see `../../libraries/auto-discover/modulette/README.md`.
