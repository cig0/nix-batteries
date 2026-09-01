# Nix-Generated Shell Behavior

Use this workflow when Nix renders POSIX-compatible shell, Fish, Nushell, or
another terminal-facing payload. The Nix expression owns evaluated data and
composition; the generated language retains ownership of its syntax and
runtime behavior.

## Preserve language boundaries

- Keep Nix data and decisions semantic until the generated-language boundary.
- Make quoting and escaping explicit for the target shell. Valid Nix
  interpolation does not prove valid shell syntax.
- Keep shared data separate from shell-specific rendering. Share neutral input
  records when practical; let each renderer own its native syntax and APIs.
- Parse or exercise generated output with its target runtime when practical.

## Terminal output ownership

- Treat each terminal content object as owning only its own visible content. It
  must not decide whether a later object begins on a new line by hiding a
  trailing newline in its payload.
- Prefer a leading newline on the content object that owns the spacing, or use
  a separate explicit newline emitter when the layout boundary is its own
  object.
- Preserve unterminated fragments only when they form one logical terminal
  object, such as a progress prefix followed by its result on the same line.
- Do not use `echo -e`. Use a target-native formatter such as `printf '%b'`
  when escape-sequence interpretation is required, and make line endings
  explicit.
- Apply the same ownership rule to executable examples in documentation.

These rules do not apply to structural newlines in data, parsers, generated
files, format strings such as `%s\n`, or separators such as
`lib.concatStringsSep "\n"`.

## Presentation boundaries

- Keep headings, spacing, colors, markers, and separators in presentation
  modules or explicit presentation data.
- Assertions validate semantic contracts, not column widths, padding, colors,
  or other cosmetic choices.
- A renderer may consume checked data but must not discover providers, attach
  provenance, or decide registry policy.
