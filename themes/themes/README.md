# lib/themes/themes - Theme Slot Maps

Each file maps semantic numbered slots to palette colors. Consumers should use
slots, not raw colors, so changing a theme does not require editing command
modules.

## What belongs here

- Theme files with the required `# ANSI theme module...` header
- Slot-to-palette assignments using the `color` argument

## What does not belong here

- Raw ANSI escape definitions; those live in `../palette.nix`
- Host theme selection; set `myOptions.hm.data.theme.name`
- Command-specific color decisions

## Real example

`nushell-inspired.nix` is the default theme. It maps `bold_zero` to green for
primary accents, `bold_four` to yellow for warnings, and `bold_five` to red for
errors. New themes should keep the same slot names and change only the color
assignment.

## Where to look next

- `../README.md` - slot assignments and available themes
- `../palette.nix` - raw ANSI color constants
