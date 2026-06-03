# help-legend/renderers - Runtime Output Adapters

These renderers turn the shared help-legend contract into shell-native text.
The layout stays shared; the syntax does not.

## What belongs here

- `posix.nix` for bash/zsh-compatible snippets
- `fish.nix` for Fish conditionals and argument handling
- `nushell.nix` for Nushell `let`, `$args`, and block syntax

## What does not belong here

- Command descriptions
- Theme color choices
- Command behavior

## Real example

All renderers implement `print` and `helpCheck`. `fish.nix` checks
`$argv[1]`; `nushell.nix` reads from `$args`; `posix.nix` checks `$1`. Same
contract, three honest runtimes.

## Where to look next

- `../README.md` - shared help-legend contract
- `README-posix.md` - POSIX usage pattern
- `README-fish.md` - Fish usage pattern
- `README-nushell.md` - Nushell usage pattern
