# Help Legend

`help-legend` renders two-column command help screens from structured Nix data:

- a command legend, where each key maps to a one-line description
- grouped command sections
- theme colors supplied by the consumer
- a renderer selected for the target runtime

The shared library owns layout, padding, section rendering, centered titles, and
one-line help checks. Consumers own command behavior, shell function names,
aliases, section order, platform gating, and detailed command-specific help.

Renderer contract:

- `print :: string -> string`
- `helpCheck :: { cmd, cmdColor, desc, pad, reset } -> string`

Available renderer docs:

- `renderers/README-posix.md`
- `renderers/README-fish.md`
- `renderers/README-nushell.md`
