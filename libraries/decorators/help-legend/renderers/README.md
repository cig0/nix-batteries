# help-legend/renderers - Runtime Output Adapters

These renderers turn the shared help-legend contract into shell-native text.
The layout stays shared; the syntax does not.

## What belongs here

- `posix.nix` for bash/zsh-compatible snippets
- `fish.nix` for Fish conditionals and argument handling
- `nushell.nix` for Nushell printing; native custom-command help owns
  `-h` and `--help`

## What does not belong here

- Command descriptions
- Theme color choices
- Command behavior

## Real example

All renderers implement `print` and `helpCheck`. `fish.nix` checks `$argv[1]`,
`posix.nix` checks `$1`, and `nushell.nix` emits a comment because Nushell
handles native help before a custom-command body runs.

## Pick the renderer

| Renderer | Use for | Function shape | Help argument | Print primitive | Validate with |
|----------|---------|----------------|---------------|-----------------|---------------|
| `libHelpLegendRenderer.posix` | bash and zsh snippets | `name() { ... }` | `$1` | `printf '%b'` | `bash -n`, `zsh -n` |
| `libHelpLegendRenderer.fish` | Fish functions | `function name ... end` | `$argv[1]` | `printf '%b'` | `fish --no-execute` |
| `libHelpLegendRenderer.nushell` | Nushell commands | `def name [] { ... }` | native `-h` / `--help` | `print --no-newline` | `nu-check` |

The Nix side should look almost identical for every renderer:

```nix
let
  L = nix-fuel.fuelLibs.helpLegendDecorator;
  libHelpLegendRenderer = L.libHelpLegendRenderer.posix; # or fish / nushell

  layout = L.sectionLayout {
    inherit groups descFn;
  };

  helpCheck =
    cmd:
    L.mkHelpCheck {
      inherit cmd layout libHelpLegendRenderer;
      desc = legend.${cmd};
      cmdColor = colors.cmd;
      reset = colors.reset;
    };
in
...
```

POSIX and Fish consumers place `${helpCheck "build"}` inside a shell-native
function body. Nushell uses its native custom-command help and uses the renderer
only for explicitly rendered titles and sections.

You might also want to check [themes](../../../themes/README.md) for semantic
color slots and terminal escape generation.

## Where to look next

- `../README.md` - shared help-legend contract
- [`themes`](../../../themes/README.md) - semantic color slots and bundled palettes
- `README-posix.md` - POSIX usage pattern
- `README-fish.md` - Fish usage pattern
- `README-nushell.md` - Nushell usage pattern
