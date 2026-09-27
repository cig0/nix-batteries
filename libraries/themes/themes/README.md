# Theme definitions

Each file in this directory is a self-contained theme. It owns the hex values
for its semantic roles and the factors used to render bold and dim variants.

Consumers use the resolver's validated output rather than importing theme
files directly. ANSI output uses the rendered presentations; tools that accept
raw hex values use the resolver's `colors` output.

## What belongs here

- Theme files with the required `# Theme module.` header
- Flat `#RRGGBB` role definitions
- Per-theme `boldFactor` and `dimFactor`
- An optional selection foreground/background pair
- Optional extra roles owned by one theme

Presentation aliases, command-specific display decisions, and escape-code
rendering do not belong in theme files.

## Required format

```nix
# Theme module. Do not remove this header.
{ }:
{
  boldFactor = 1.0;
  dimFactor = 0.55;

  selection = {
    background = "#ffff00";
    foreground = "#000000";
  };

  roles = {
    accent = "#5e81ac";
    emphasis = "#d8dee9";
    option = "#88c0d0";
    success = "#a3be8c";
    value = "#ebcb8b";
    warning = "#ebcb8b";
    error = "#bf616a";
    notice = "#d08770";
    context = "#a3be8c";
  };
}
```

A theme declares one color per role and nothing else. `ansi-renderer.nix`
derives `base.<role>`, `bold.<role>`, and `dim.<role>` from that color, so a
theme never writes a presentation name.

## Roles

| Role       | Meaning                                                           |
| ---------- | ----------------------------------------------------------------- |
| `accent`   | Headings, section titles, banners                                 |
| `emphasis` | Command names, literal input, examples, inline emphasis           |
| `option`   | Flags and keyboard chords                                         |
| `success`  | Completed successful outcomes                                     |
| `value`    | Values, counts, durations, timestamps, placeholders, model names  |
| `warning`  | Cautions and potentially hazardous conditions                     |
| `error`    | Failures, invalid or missing required input, reported conflicts   |
| `notice`   | Progress, skipped operations, state changes, dirty-state notices  |
| `context`  | Source identity, repository or host metadata, locations and paths |

Two roles may share a hex value. Bundled themes do so where a palette has no
distinct color for the two meanings.

## Selection colors

Interactive selectors may need colors that terminal-output roles do not
describe. A theme can opt in with both fields below:

```nix
selection = {
  background = "#ffff00";
  foreground = "#000000";
};
```

`background` identifies the selected-row background. `foreground` identifies
text drawn on that background. Defining the pair in the theme avoids asking
consumers to infer contrast or UI roles from output roles. Both values must use
`#RRGGBB`; partial pairs and additional selection fields are rejected.

## Factors

- `boldFactor` scales the RGB source for the `bold` group before applying SGR
  bold.
- `dimFactor` scales the RGB source for the `dim` group before regular
  true-color rendering.
- The `base` group renders each RGB source without scaling.
- Scaled channels are floored and clamped to 255.

Factors default to `1.0` and `0.55`, respectively, and must be non-negative
numbers. Bundled themes declare both fields explicitly so their tuning is
visible beside their colors.

## Validation

Every theme must define all nine roles listed above under `roles`. Every role
and selection color must be a string in the exact `#RRGGBB` form.

Extra roles are allowed and receive the same presentation in each of the three
groups. A role may not be named `selection`, because that name is reserved for
the raw selection pair published beside the roles in `colors`.

Theme files are evaluated lazily by Nix, so fixture checks force all bundled
themes to ensure invalid colors, factors, reserved names, or missing roles fail
during repository validation.

## Adding a theme

1. Copy an existing theme file.
2. Keep the required Modulette header.
3. Replace every role color with a value that belongs to the new theme.
4. Tune `boldFactor` and `dimFactor`.
5. Run the theme fixtures and the full flake checks.

The theme becomes available under the filename without `.nix`.

## Where to look next

- `../README.md` — public API, role meanings, and integration
- `../resolver.nix` — public orchestration and selection API
- `../assertions.nix` — source validation and required-role enforcement
- `../normalizer.nix` — defaults and canonical theme representation
- `../ansi-renderer.nix` — factor-aware escape-code rendering
