# Configuration Options

The module importer function accepts an attribute set with these parameters:

| Option         | Type            | Description                                                                                                | Default |
|----------------|-----------------|-----------------------------------------------------------------------------------------------------------|---------|
| `dirs`         | List of paths   | **Required.** Directories to scan recursively for modules.                                                | `[]`    |
| `excludePaths` | List of strings | Whole relative path components to exclude (e.g., `"tests"`, `"experimental"`). | `[]` |
| `discoveryMode` | String | `"modules"` for module-only roots; `"heuristic"` for approximate mixed-tree classification. | `"heuristic"` |
| `extraModules` | List of paths   | Specific module files to include directly. Useful for including modules within an otherwise excluded path.| `[]`    |

## Example Usage

```nix
(moduleImporter {
  dirs = [ ./modules ./profiles ];
  excludePaths = [ "/tests/" "/experimental/" ];
  extraModules = [ ./special/important-module.nix ];
})
```

## Default Excluded Files

Modulon automatically excludes these filenames (exact match):

- `configuration.nix`
- `flake.nix`
- `hardware-configuration.nix`
- `home.nix`

And these directory components below each scan root:

- `.git/`
- `/tests/`

See `modulon/default.nix` for the complete list.

Leading/trailing slashes in existing exclusions are accepted and normalized.
Matching is now component-based and relative to each root: `"test"` no longer
excludes `"latest"`, and an ancestor named `tests` does not suppress the root.
Absolute paths must be replaced with the relevant below-root component sequence.
Empty patterns and `.`/`..` components fail explicitly. `extraModules` continues
to bypass every exclusion. Symlinks are not followed.
