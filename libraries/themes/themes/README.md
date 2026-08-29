# Theme definitions

Each file in this directory is a self-contained theme. It owns the hex values
for its semantic slots and the factors used to render bold and dimmed
variants.

Consumers use the resolver's validated output rather than importing theme
files directly. ANSI output uses rendered slots; tools that accept raw hex
values use the resolver's `colors` output.

## What belongs here

- Theme files with the required `# Theme module.` header
- Flat `#RRGGBB` slot definitions
- Per-theme `boldFactor` and `dimFactor`
- An optional selection foreground/background pair
- Optional specialized slots owned by one theme

Command-specific display decisions and escape-code rendering do not belong in
theme files.

## Required format

```nix
# Theme module. Do not remove this header.
{ }:
rec {
  boldFactor = 1.0;
  dimFactor = 0.55;

  selection = {
    background = slots.seven;
    foreground = "#000000";
  };

  slots = rec {
    zero = "#5e81ac";
    one = "#d8dee9";
    two = "#88c0d0";
    three = "#b48ead";
    four = "#ebcb8b";
    five = "#bf616a";
    six = "#d08770";
    seven = "#a3be8c";

    bold_zero = zero;
    bold_one = one;
    bold_two = two;
    bold_three = three;
    bold_four = four;
    bold_five = five;
    bold_six = six;
    bold_seven = seven;

    dimmed_zero = zero;
    dimmed_one = one;
  };
}
```

The recursive attrset is ordinary Nix. Assigning `bold_zero = zero` and
`dimmed_zero = zero` makes their shared source color explicit while allowing
the resolver to apply different rendering behavior.

## Selection colors

Interactive selectors may need colors that numbered terminal-output slots do
not describe. A theme can opt in with both fields below:

```nix
selection = {
  background = slots.seven;
  foreground = "#000000";
};
```

`background` identifies the selected-row background. `foreground` identifies
text drawn on that background. Defining the pair in the theme avoids asking
consumers to infer contrast or UI roles from numbered slots. Both values must
use `#RRGGBB`; partial pairs and additional selection fields are rejected.

## Factors

- `boldFactor` scales the RGB source for `bold_*` slots before applying SGR
  bold.
- `dimFactor` scales the RGB source for `dimmed_*` slots before regular
  true-color rendering.
- Unprefixed slots render their RGB source without scaling.
- Scaled channels are floored and clamped to 255.

Factors default to `1.0` and `0.55`, respectively, and must be non-negative
numbers. Bundled themes declare both fields explicitly so their tuning is
visible beside their colors.

## Validation

Every theme must define:

- `zero` through `seven`
- `bold_zero` through `bold_seven`
- `dimmed_zero` and `dimmed_one`

Every slot and selection color must be a string in the exact `#RRGGBB` form.
Additional slots are allowed and follow the same prefix rules.

Theme files are evaluated lazily by Nix, so fixture checks force all bundled
themes to ensure invalid colors, factors, or missing slots fail during
repository validation.

## Adding a theme

1. Copy an existing theme file.
2. Keep the required Modulette header.
3. Replace all prime slot colors with values that belong to the new theme.
4. Assign the bold and dimmed slots to their intended prime colors.
5. Tune `boldFactor` and `dimFactor`.
6. Run the theme fixtures and the full flake checks.

The theme becomes available under the filename without `.nix`.

## Where to look next

- `../README.md` — public API, slot roles, and integration
- `../resolver.nix` — validation, factor scaling, and escape-code rendering
