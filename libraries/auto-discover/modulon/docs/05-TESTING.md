# Testing Modulon

This `nix-nitro` tree validates Modulon through focused flake checks, fixture
evaluation, and direct parser checks.

Start with the standard flake command:

```shell
nix flake check
```

That builds the checks for the current host system. To evaluate the complete
supported system matrix from one host without trying to cross-build incompatible
derivations, use:

```shell
nix flake check --all-systems --no-build
```

Nix still reports `nitroLibs` as an unchecked flake output because custom
library outputs are not standard buildable output types. The committed `checks`
exercise the public library surface and focused fixtures directly.

## Understanding Output

By default, Nix only shows detailed build logs if a check fails. If `nix flake
check` exits with status code 0, all checks passed.

The check set includes a Modulon fixture that verifies:

- a valid module in `fixtures/modulon/modules/` is discovered
- a module marked with `@MODULON_SKIP` is ignored
- an explicitly supplied `extraModules` entry is preserved

For a fast library-surface check:

```shell
nix eval --no-write-lock-file --json '.#nitroLibs' --apply builtins.attrNames
```

Expected output includes `modulon`:

```json
[
  "dynamicAliases",
  "flakeRoot",
  "gitRepoState",
  "guardFlakeInput",
  "helpLegendDecorator",
  "mkGitRepoState",
  "modulette",
  "modulon",
  "nixOptionsToMd",
  "themes"
]
```

## Parser Check

Use this after editing the collector itself:

```bash
nix-instantiate --parse modulon/default.nix >/dev/null
```

## Debugging Consumer Failures

If a consumer fails after adding a module, inspect these first:

- The directory passed through `dirs` exists
- The file ends in `.nix`
- The file content matches at least two module detection patterns
- The file does not contain `@MODULON_SKIP`
- The path does not match `excludePaths` or default exclusions
