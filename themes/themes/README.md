# lib/themes/themes - Theme Slot Maps

Each file maps semantic numbered slots to palette colors. Themes declare
which palette they consume and may override individual palette colors.
Consumers should use slots, not raw colors, so changing a theme does not
require editing command modules.

## What belongs here

- Theme files with the required `# Theme module.` header
- Each theme declares its palette, optional overrides, and slot-to-color
  assignments

## What does not belong here

- Hex color definitions; those live in `../palettes/`
- Palette selection at the host level; set `myOptions.hm.data.theme.name`
- Command-specific color decisions

## Theme file format

Every theme file is a function that returns an attrset with `palette` and
`slots`:

```nix
# Theme module. Do not remove this header.
{ }:
{
  palette = "tailwind-inspired";
  slots = { color }:
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
  };
}
```

- **`palette`** — name of the palette file in `../palettes/` (without
  `.nix`). The palette is immutable; its hex values are the base for
  `color.*` lookups.
- **`overrides`** — optional `name → "#hex"` patches to the palette colors.
  Overridden colors affect all variants (regular, bold, dimmed) for that
  name. Omit when empty — `palette.nix` defaults to `{ }`.
- **`dimFactor`** — optional dimming intensity for `color.dimmed.*`
  (default: `0.55`). Multiply each RGB channel by this value. Lower =
  dimmer. Omit when you want the default.
- **`slots`** — function from `{ color }` to the slot attrset. Maps
  semantic slot names to `color.*` references.

## Overrides example

`steel.nix` is a bundled theme that uses overrides — Tailwind palette with a
muted blue:

```nix
# Theme module. Do not remove this header.
# Steel — Tailwind palette with a muted blue override
{ }:
{
  palette = "tailwind-inspired";
  overrides = { blue = "#4a6fa5"; };
  slots = { color }:
  {
    bold_zero = color.bold.blue;    # ← #4a6fa5, not the palette's #3b82f6
    bold_one  = color.bold.white;
    # ...
  };
}
```

Patched hex flows into `color.*` automatically — `color.bold.blue`,
`color.blue`, and `color.dimmed.blue` all derive from the overridden
`#4a6fa5`.

`dimFactor` controls how much `color.dimmed.*` is dimmed. The default
is `0.55` — lower values produce dimmer colors. A theme on a dark
background might use `dimFactor = 0.4` for deeper dimming:

```nix
{ }:
{
  palette = "crt";
  dimFactor = 0.4;
  slots = { color }:
  {
    dimmed_zero = color.dimmed.orange;  # dimmed at 40% instead of 55%
    # ...
  };
}
```

Overrides can replace existing palette colors **or add new ones**. If a theme
needs a color that doesn't exist in its chosen palette, add it via overrides
rather than modifying the palette file.

Overrides only affect the theme declaring them. Other themes using the same
palette are unaffected — palettes are immutable.

## Where to look next

- `../README.md` - slot assignments and available themes
- `../palette.nix` - palette discovery, hex rendering, theme resolution
- `../palettes/` - palette files (immutable hex color sets)