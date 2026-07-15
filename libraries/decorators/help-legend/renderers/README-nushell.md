# Nushell Help Legend Renderer

`libHelpLegendRenderer.nushell` maps shared help-legend sections and titles to
Nushell `print --no-newline` statements.

## Runtime boundary

Nushell provides `-h` and `--help` for custom commands before their bodies run.
The renderer therefore leaves `helpCheck` as an explanatory generated comment;
it does not inspect `$args` or replace Nushell's native command help.

Explicit project help screens still use the shared layout functions:

```nix
let
  L = nix-fuel.fuelLibs.helpLegendDecorator;
  libHelpLegendRenderer = L.libHelpLegendRenderer.nushell;

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

  projectSection = L.mkHelpSection {
    inherit libHelpLegendRenderer groups descFn layout;
    cmdColor = "\\e[1;36m";
    headerColor = "\\e[1;33m";
    reset = "\\e[0m";
  };
in
''
  def project-help [] {
    ${projectSection.text}
  }
''
```

Theme values enter the shared API as textual `\e[...]` escapes. The Nushell
renderer converts them to Nushell-native `\u{1b}[...]` escapes in generated
source. Nushell does not interpret `\e` or octal-looking `\033` strings as ESC.

## Generated shape

The section above produces statements shaped like:

```nu
print --no-newline "\n\u{1b}[1;33mProject\u{1b}[0m"
print --no-newline "\n  \u{1b}[1;36mbuild\u{1b}[0m  Build the project output"
```

Validate generated files with `nu-check`, then execute decorated fixtures when
runtime escape behavior matters. Source checks should find textual `\u{1b}`;
runtime checks should find byte `0x1B`.

## Where to look next

- `../README.md` - shared layout and renderer API
- `README.md` - runtime adapter boundary
- `../../../themes/README.md` - semantic color slots and escape generation
