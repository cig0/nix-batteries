# POSIX Help Legend Renderer

Use `libHelpLegendRenderer.posix` for POSIX-compatible command modules
(`dash`, `bash`, and `zsh` all accept the generated snippets).

The renderer maps the common help-legend contract to POSIX shell snippets:

- `print text` emits `printf '%b' "text"`.
- `escape text` makes one literal value safe inside that payload. Expansion
  characters are backslash-escaped and a literal backslash becomes `\0134`.
- Theme colour and mode values are rewritten from `\e` to `\033`, because
  dash's `printf '%b'` prints `\e` literally while `\033` is ESC everywhere.
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
libHelpLegendRenderer = L.libHelpLegendRenderer.posix;

helpCheck =
  cmd:
  L.mkHelpCheck {
    inherit cmd layout libHelpLegendRenderer;
    desc = legend.${cmd};
    cmdColor = libThemes.theme.bold.emphasis;
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
    _ack "${libThemes.theme.bold.emphasis}===> ${legend.${cmd}}${libThemes.mode.reset}" "''${x}" || return
  '';
```

In that pattern, `ackBeforeRun` is a Nix function returning shell code, while
`_ack` is a generated POSIX shell function owned by the consumer module.

## Step-by-step implementation

Use this when a Nix module generates shell functions for POSIX-compatible
shells.

### 1. Select the renderer

```nix
let
  L = nix-batteries.batteriesLib.helpLegendDecorator;
  libHelpLegendRenderer = L.libHelpLegendRenderer.posix;
in
...
```

### 2. Define shared command data

```nix
let
  colors = {
    cmd = "\\e[1;36m";
    header = "\\e[1;33m";
    reset = "\\e[0m";
  };

  legend = {
    build = "Build the project output";
    test = "Run the test suite";
    lint = "Run formatting and lint checks";
  };

  groups = [
    {
      name = "Project";
      cmds = [ "build" "test" "lint" ];
    }
  ];

  descFn = cmd: legend.${cmd};
  layout = L.sectionLayout { inherit groups descFn; };
in
...
```

### 3. Build the reusable help guard

```nix
let
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

For `build`, the renderer emits POSIX-compatible shell code shaped like this:

```sh
{ [ "$1" = "-h" ] || [ "$1" = "--help" ]; } && {
  printf '%b' "\n  build  Build the project output"
  printf '%b' "\n"
  return 0
}
```

### 4. Put the guard inside real functions

```nix
functions = ''
  build() {
    ${helpCheck "build"}
    nix build
  }

  test() {
    ${helpCheck "test"}
    nix flake check
  }

  lint() {
    ${helpCheck "lint"}
    nix fmt
  }
'';
```

Now `build --help` prints the one-line legend entry and returns before running
`nix build`.

### 5. Add a full help screen

```nix
let
  projectSection = L.mkHelpSection {
    inherit libHelpLegendRenderer groups descFn layout;
    cmdColor = colors.cmd;
    headerColor = colors.header;
    reset = colors.reset;
  };

  helpFunction = ''
    project-help() {
      ${projectSection.text}
    }
  '';
in
helpFunction
```

Validate the generated shell with `bash -n`, `zsh -n`, and `dash -n` when those
shells are available.
