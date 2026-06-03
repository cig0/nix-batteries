# Testing Modulon

This extracted `nix-ignite` tree currently validates Modulon through flake
evaluation and direct parser checks. Dedicated Modulon check derivations can be
added later if the module collector grows more behavior.

Start with the standard flake command:

```shell
nix flake check
```

## Understanding Output

By default, Nix only shows detailed build logs if a check fails. If
`nix flake check` runs silently and exits with status code 0, all checks passed.

For a fast library-surface check:

```shell
nix eval --no-write-lock-file --json '.#lib' --apply builtins.attrNames
```

Expected output includes `modulon`:

```json
["flakeVersion","guardFlakeInput","helpLegendDecorator","modulette","modulon","themes"]
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
