# decorators - Rendering Helpers

Decorators format generated text. They should not decide what commands do; they
only help consumers present data consistently.

## What belongs here

- Shared rendering helpers
- Runtime-specific renderers when a common contract needs shell-native output

## What does not belong here

- Command behavior
- Theme definitions
- Shell aliases or functions

## Real example

`help-legend/` owns the two-column command help layout used by the Nix command
helpers. The command module still owns command names, descriptions, aliases, and
runtime behavior.

The useful split looks like this:

1. The consumer defines command data:

   ```nix
   legend = {
     build = "Build the project";
     test = "Run the test suite";
   };

   groups = [
     {
       name = "Project";
       cmds = [ "build" "test" ];
     }
   ];
   ```

2. The decorator computes layout and renders shell-native snippets:

   ```nix
   L = nix-ignite.lib.helpLegendDecorator;
   renderer = L.renderers.posix;

   layout = L.sectionLayout {
     inherit groups;
     descFn = cmd: legend.${cmd};
   };
   ```

3. The shell module places those snippets inside real functions:

   ```sh
   build() {
     # generated help check goes here
     nix build
   }
   ```

That keeps reusable presentation logic in the library while the project remains
in charge of behavior, aliases, theme colors, and command-specific help.

## Where to look next

- `help-legend/README.md` - end-to-end help legend walkthrough
- `help-legend/renderers/README.md` - renderer selection guide
- `help-legend/renderers/README-posix.md` - POSIX implementation pattern
- `help-legend/renderers/README-fish.md` - Fish implementation pattern
- `help-legend/renderers/README-nushell.md` - Nushell implementation pattern
