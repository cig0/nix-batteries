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

## Pick the renderer

| Renderer | Use for | Function shape | Help argument | Print primitive | Validate with |
|----------|---------|----------------|---------------|-----------------|---------------|
| `renderers.posix` | bash and zsh snippets | `name() { ... }` | `$1` | `printf '%b'` | `bash -n`, `zsh -n` |
| `renderers.fish` | Fish functions | `function name ... end` | `$argv[1]` | `printf '%b'` | `fish -n` |
| `renderers.nushell` | Nushell commands | `def name [...args: string] { ... }` | `$args` | `print --no-newline` | `nu --commands` |

The Nix side should look almost identical for every renderer:

```nix
let
  L = nix-ignite.igniteLibs.helpLegendDecorator;
  renderer = L.renderers.posix; # or fish / nushell

  layout = L.sectionLayout {
    inherit groups descFn;
  };

  helpCheck =
    cmd:
    L.mkHelpCheck {
      inherit cmd renderer layout;
      desc = legend.${cmd};
      cmdColor = colors.cmd;
      reset = colors.reset;
    };
in
...
```

The consumer module then places `${helpCheck "build"}` inside a shell-native
function body. That placement is the only part that should change per runtime.

You might also want to check [themes](../../themes/README.md) for a more robust way to handle colors and themes in the terminal.

## Where to look next

- `../README.md` - shared help-legend contract
- [`themes`](../../themes/README.md) - semantic color slots and bundled palettes
- `README-posix.md` - POSIX usage pattern
- `README-fish.md` - Fish usage pattern
- `README-nushell.md` - Nushell usage pattern
