# Nushell Help Legend Renderer

Use `renderers.nushell` for Nushell command modules.

The renderer maps the common help-legend contract to Nushell snippets:

- `print text` emits `print --no-newline "text"`.
- `helpCheck` reads the first item from `$args`, checks for `-h` or `--help`,
  prints one aligned legend row, and returns.

Expected function shape:

```nu
def build [...args] {
  # generated helpCheck goes here
  nix build
}
```

Nix module pattern:

```nix
renderer = L.renderers.nushell;

helpCheck =
  cmd:
  L.mkHelpCheck {
    inherit cmd renderer layout;
    desc = legend.${cmd};
    cmdColor = libThemes.theme.bold_zero;
    reset = libThemes.mode.reset;
  };
```

This renderer assumes generated functions expose runtime arguments as `args`,
for example `def name [...args] { ... }`. Treat this implementation as the
initial Nushell backend and validate it against the first real Nushell consumer.
