# POSIX Help Legend Renderer

Use `renderers.posix` for bash/zsh-compatible command modules.

The renderer maps the common help-legend contract to POSIX shell snippets:

- `print text` emits `printf '%b' "text"`.
- `helpCheck` checks `$1` for `-h` or `--help`, prints one aligned legend row,
  and returns `0`.

Expected function shape:

```sh
build() {
  # generated helpCheck goes here
  nix build
}
```

Nix module pattern:

```nix
renderer = L.renderers.posix;

helpCheck =
  cmd:
  L.mkHelpCheck {
    inherit cmd renderer layout;
    desc = legend.${cmd};
    cmdColor = libThemes.theme.bold_zero;
    reset = libThemes.mode.reset;
  };
```

Composed helpers are valid. For example, a Nix helper can include
`${helpCheck cmd}` before module-specific ACK or confirmation logic:

```nix
ackBeforeRun =
  cmd:
  ''
    ${helpCheck cmd}
    _ack "${libThemes.theme.bold_zero}===> ${legend.${cmd}}${libThemes.mode.reset}" "''${x}" || return
  '';
```

In that pattern, `ackBeforeRun` is a Nix function returning shell code, while
`_ack` is a generated POSIX shell function owned by the consumer module.
