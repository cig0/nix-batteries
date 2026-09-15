![A two-column command help screen renderer.](./assets/images/help-legend.png)

<p align="center" style="font-size: 1.5em;"><strong>Help Legend 🛟</strong></p>

<p align="center"><em>Help screen renderer</em></p>

<br>

### What

`help-legend` renders two-column command help screens from structured Nix data:

- a command legend, where each key maps to a one-line description
- grouped command sections
- theme colors supplied by the consumer
- a renderer selected for the target runtime

<br>

The shared library owns layout, padding, section rendering, centered titles, and
one-line help checks. Consumers own command behavior, shell function names,
aliases, section order, platform gating, and detailed command-specific help.

<br>

---

<br>

### Mental model

Build command help in three layers:

1. **Project data**: command names, descriptions, sections, and theme colors.
2. **Shared layout**: column width, padding, section rendering, centered titles.
3. **Runtime renderer**: POSIX, Fish, or Nushell syntax for printing. POSIX and
   Fish also provide explicit `-h` / `--help` checks; Nushell provides native
   custom-command help.

The renderer changes shell syntax only. The command data and layout calls stay
the same.

<br>

### Step-by-step example

This example builds a small `daily-tools` help screen and one-line help checks
for generated shell functions.

#### 1. Pick the library and renderer

```nix
let
  L = nix-batteries.sidecarLibs.helpLegendDecorator;
  libHelpLegendRenderer = L.libHelpLegendRenderer.posix;
in
...
```

Use `L.libHelpLegendRenderer.fish` or `L.libHelpLegendRenderer.nushell` when
the generated functions target those shells.

#### 2. Define command descriptions and groups

```nix
let
  legend = {
    build = "Build the project output";
    test = "Run the test suite";
    lint = "Run formatting and lint checks";
    release = "Create the release artifact";
  };

  groups = [
    {
      name = "Project";
      cmds = [ "build" "test" "lint" ];
    }
    {
      name = "Release";
      cmds = [ "release" ];
    }
  ];

  descFn = cmd: legend.${cmd};
in
...
```

`groups` controls display order. `legend` owns the text. The shell function
bodies still live in the consumer module.

#### 3. Compute one layout for the whole help screen

```nix
let
  layout = L.sectionLayout {
    inherit groups descFn;
  };
in
...
```

Sharing one layout keeps descriptions aligned across every section.

#### 4. Create a reusable help check

```nix
let
  colors = {
    cmd = "\\e[1;36m";
    header = "\\e[1;33m";
    title = "\\e[1;32m";
    reset = "\\e[0m";
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

For POSIX and Fish, insert `${helpCheck "build"}` at the top of the generated
`build` function. If the user runs `build --help`, the function prints one
aligned row and exits before running the command body. Nushell reserves those
flags for native custom-command help.

#### 5. Render the full help screen

```nix
let
  section = L.mkHelpSection {
    inherit libHelpLegendRenderer groups descFn;
    layout = layout;
    cmdColor = colors.cmd;
    headerColor = colors.header;
    reset = colors.reset;
  };

  dailyToolsHelp = ''
    daily-tools-help() {
      ${L.mkCenteredTitle {
        inherit libHelpLegendRenderer;
        color = colors.title;
        reset = colors.reset;
        title = "Daily Tools";
        width = section.width;
      }}
      ${section.text}
    }
  '';
in
dailyToolsHelp
```

The generated function prints a centered title and the grouped two-column help
screen.

#### 6. Place help checks inside real functions

POSIX-shaped consumer code:

```nix
functions = ''
  ${dailyToolsHelp}

  build() {
    ${helpCheck "build"}
    nix build
  }

  test() {
    ${helpCheck "test"}
    nix flake check
  }
'';
```

For Fish or Nushell, keep the same Nix data and switch only the renderer plus
the shell function wrapper syntax. Nushell commands omit the explicit help
check because its parser owns `-h` and `--help`.

<br>

### Multi-shell project shape

For a real project, keep the data and layout in one shared Nix file that accepts
`libHelpLegendRenderer` as an argument:

```nix
# daily-tools-help.nix
{ libHelpLegendDecorator, libHelpLegendRenderer }:
let
  L = libHelpLegendDecorator;

  legend = {
    build = "Build the project output";
    test = "Run the test suite";
  };

  groups = [
    {
      name = "Project";
      cmds = [ "build" "test" ];
    }
  ];

  descFn = cmd: legend.${cmd};
  layout = L.sectionLayout { inherit groups descFn; };

  colors = {
    cmd = "\\e[1;36m";
    header = "\\e[1;33m";
    reset = "\\e[0m";
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
{
  inherit helpCheck legend;
}
```

Then each shell module imports that file with its own renderer:

```nix
# posix-tools.nix
let
  shared = import ./daily-tools-help.nix {
    inherit libHelpLegendDecorator;
    libHelpLegendRenderer = libHelpLegendDecorator.libHelpLegendRenderer.posix;
  };
in
''
  build() {
    ${shared.helpCheck "build"}
    nix build
  }
''
```

Fish uses the same shared import and changes only the renderer plus the function
wrapper syntax. Nushell uses the same shared layout and section rendering but
leaves `-h` and `--help` to native custom-command help.

<br>

### API quick reference

- `sectionLayout { groups, descFn, indent ? 2, minGap ? 2 }` computes shared
  alignment data.
- `mkHelpCheck { cmd, desc, layout, libHelpLegendRenderer, cmdColor, reset }` renders the
  per-command `-h` / `--help` guard.
- `mkHelpSection { groups, descFn, layout, libHelpLegendRenderer, cmdColor, headerColor,
reset, closing ? [ ] }` renders grouped rows.
- `mkCenteredTitle { title, width, libHelpLegendRenderer, color, reset, leadingLines ? 1 }`
  renders a centered heading.
- `enabledWidth sections` returns the widest enabled section width when a help
  screen is assembled conditionally.
- `libHelpLegendRenderer.posix`, `libHelpLegendRenderer.fish`, and
  `libHelpLegendRenderer.nushell` adapt the shared contract to shell-native
  output.

Renderer contract:

- `print :: string -> string`
- `helpCheck :: { cmd, cmdColor, desc, pad, reset } -> string`

<br>

### Renderer docs

- `renderers/README-posix.md`
- `renderers/README-fish.md`
- `renderers/README-nushell.md`
