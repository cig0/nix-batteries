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

## Step-by-step implementation

Use this when a Nix module generates Nushell commands.

### 1. Select the renderer

```nix
let
  L = nix-ignite.igniteLibs.helpLegendDecorator;
  renderer = L.renderers.nushell;
in
...
```

### 2. Define shared command data

```nix
let
  colors = {
    cmd = "\\033[1;36m";
    header = "\\033[1;33m";
    reset = "\\033[0m";
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
      inherit cmd renderer layout;
      desc = legend.${cmd};
      cmdColor = colors.cmd;
      reset = colors.reset;
    };
in
...
```

For `build`, the renderer emits Nushell code shaped like this:

```nu
let __help_arg = ($args | get 0? | default "")
if ($__help_arg == "-h" or $__help_arg == "--help") {
  print --no-newline "\n  build  Build the project output"
  print --no-newline "\n"
  return
}
```

### 4. Put the guard inside real commands

```nix
functions = ''
  def build [...args: string] {
    ${helpCheck "build"}
    nix build
  }

  def test [...args: string] {
    ${helpCheck "test"}
    nix flake check
  }

  def lint [...args: string] {
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
    inherit renderer groups descFn layout;
    cmdColor = colors.cmd;
    headerColor = colors.header;
    reset = colors.reset;
  };

  helpFunction = ''
    def project-help [] {
      ${projectSection.text}
    }
  '';
in
helpFunction
```

Validate the generated command text with the same Nushell parse check used by
your project, for example `nu --commands`.
