# lib/decorators - Rendering Helpers

Decorators format generated text. They should not decide what commands do; they
only help consumers present data consistently.

## What belongs here

- Shared rendering helpers
- Runtime-specific renderers when a common contract needs shell-native output

## What does not belong here

- Command behavior
- Theme definitions
- Shell aliases or functions

## Real example

`help-legend/` owns the two-column command help layout used by the Nix command
helpers. The command module still owns command names, descriptions, aliases, and
runtime behavior.

## Where to look next

- `help-legend/README.md` - layout contract
- `help-legend/renderers/README-posix.md` - POSIX renderer
- `help-legend/renderers/README-fish.md` - Fish renderer
- `help-legend/renderers/README-nushell.md` - Nushell renderer
