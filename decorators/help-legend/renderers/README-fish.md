# Fish Help Legend Renderer

Use `renderers.fish` for fish command modules.

The renderer maps the common help-legend contract to fish snippets:

- `print text` emits `printf '%b' "text"`.
- `helpCheck` checks `$argv[1]` for `-h` or `--help`, prints one aligned legend
  row, and returns `0`.

Expected function shape:

```fish
function build
  # generated helpCheck goes here
  nix build
end
```

Nix module pattern:

```nix
renderer = L.renderers.fish;

helpCheck =
  cmd:
  L.mkHelpCheck {
    inherit cmd renderer layout;
    desc = legend.${cmd};
    cmdColor = libThemes.theme.bold_zero;
    reset = libThemes.mode.reset;
  };
```

If a command group needs shared behavior, wrap `helpCheck` in a module-local Nix
helper just like POSIX modules do. The wrapper should emit fish syntax after the
help check.
