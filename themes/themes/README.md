# lib/themes/themes - Theme Slot Maps

Each file maps semantic numbered slots to palette colors. Consumers should use
slots, not raw colors, so changing a theme does not require editing command
modules.

## What belongs here

- Theme files with the required `# Theme module.` header
- Slot-to-palette assignments using the `color` argument

## What does not belong here

- Hex color definitions; those live in `../palette.nix`
- Host theme selection; set `myOptions.hm.data.theme.name`
- Command-specific color decisions

## Real example

`nushell-inspired.nix` is the canonical default theme:

```nix
# Theme module. Do not remove this header.
{ color }:
{
  bold_zero  = color.bold.green;
  bold_one   = color.bold.white;
  bold_two   = color.bold.blue;
  bold_three = color.bold.magenta;
  bold_four  = color.bold.yellow;
  bold_five  = color.bold.red;
  dimmed_zero = color.dimmed.green;
  dimmed_one  = color.dimmed.white;
  zero  = color.green;
  one   = color.white;
  two   = color.blue;
  three = color.magenta;
  four  = color.yellow;
  five  = color.red;
}
```

Every theme receives `{ color }` from the palette and maps slots to `color.*`
names.

## Where to look next

- `../README.md` - slot assignments and available themes
- `../palette.nix` - hex color definitions and rendering