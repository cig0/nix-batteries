# Excluding Modules

You have several ways to prevent files or directories from being imported.
Prefer the smallest exclusion that matches the intent: use `@MODULON_SKIP` for a
single nearby file, and `excludePaths` for whole paths or recurring patterns.

## Using excludePaths

Provide whole relative path components when calling the module importer function.

Patterns match consecutive components at any depth below each declared root.
`foo` and `/foo/` both match `bar/foo/baz.nix`, but never `foobar/baz.nix`.
Excluded directories are pruned before traversal. Parent directories above the
root never participate. Legacy boundary slashes are accepted, while absolute
paths and partial-name fragments must be migrated to relative components.

**Examples:**

Exclude any module(s) with the name `test.nix`, and any path containing `/experimental/`:

```nix
excludePaths = [ "tests.nix" "/experimental/" ];
```

If you have modules with the same name and want to exclude specific ones:

```nix
excludePaths = [ "path/to/tests.nix" "path/to/experimental/" ];
```

## Using @MODULON_SKIP Tag

_Added in v0.1.1_

Add `@MODULON_SKIP` anywhere in your module file (recommended at the top), and
Modulon will skip it without needing to modify the exclusion list.

This is the easiest way to keep files close to their owning module while making
the boundary explicit. Typical examples:

- Data modules imported manually by a renderer
- Helper modules that are not valid module-system entries
- Logic modules you want to keep nearby while they are disabled or being reworked

This is especially useful when you have a module structure like this:

```
.
├── packages
│   ├── baseline.nix
│   ├── cli.nix
│   ├── default.nix    ← Add @MODULON_SKIP here
│   ├── gui.nix
│   └── tryout.nix
```

Without this tag, you'd need to exclude the entire directory and then re-include specific files:

```nix
(libModulon {
  excludePaths = [ "/applications/packages/" ];
  extraModules = [
    "${self}/configs/nixos/modules/applications/packages/default.nix"
  ];
})
```

With the tag, just add `@MODULON_SKIP` to the file you want to skip.

## Other Methods

- **Rename Files** — Change a module's filename extension (e.g., `.nix.dis`) so it's no longer picked up
- **Directory Structure** — Place modules you don't want automatically imported outside the directories listed in `dirs`
