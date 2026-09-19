# Fish Help Legend Renderer

Use `libHelpLegendRenderer.fish` for fish command modules.

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
libHelpLegendRenderer = L.libHelpLegendRenderer.fish;

helpCheck =
  cmd:
  L.mkHelpCheck {
    inherit cmd layout libHelpLegendRenderer;
    desc = legend.${cmd};
    cmdColor = libThemes.theme.bold_emphasis;
    reset = libThemes.mode.reset;
  };
```

If a command group needs shared behavior, wrap `helpCheck` in a module-local Nix
helper just like POSIX modules do. The wrapper should emit fish syntax after the
help check.

## Step-by-step implementation

Use this when a Nix module generates Fish functions.

### 1. Select the renderer

```nix
let
  L = nix-batteries.batteriesLib.helpLegendDecorator;
  libHelpLegendRenderer = L.libHelpLegendRenderer.fish;
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

For `build`, the renderer emits Fish code shaped like this:

```fish
if test "$argv[1]" = "-h"; or test "$argv[1]" = "--help"
  printf '%b' "\n  build  Build the project output"
  printf '%b' "\n"
  return 0
end
```

### 4. Put the guard inside real functions

```nix
functions = ''
  function build
    ${helpCheck "build"}
    nix build
  end

  function test
    ${helpCheck "test"}
    nix flake check
  end

  function lint
    ${helpCheck "lint"}
    nix fmt
  end
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
    function project-help
      ${projectSection.text}
    end
  '';
in
helpFunction
```

Validate the generated function text with `fish -n`.
