# Nix Refactor

Use this workflow to restructure existing Nix code while preserving its
observable behavior. If behavior must change, separate and name that change.

## Establish the contract

1. Identify public options, flake outputs, generated artifacts, package results,
   and supported systems affected by the code.
2. Record focused evaluation or build probes that characterize current
   behavior.
3. Inspect callers before moving ownership, changing arguments, or extracting
   helpers.

## Refactor

- Optimize first for clearer intent and ownership, then for reduced evaluation
  work and duplication. Line count is not a quality metric.
- Keep source data, normalization and decision logic, generated presentation,
  and activation effects in explicit layers. Do not move presentation choices
  into assertions or validation policy.
- Introduce an abstraction only when it removes repeated decisions or
  complexity for multiple callers.
- Keep a one-caller expression local unless extraction creates a meaningful
  boundary.
- Avoid overlays when ordinary package arguments, module arguments, or direct
  imports express the dependency.
- Preserve option names, defaults, priorities, list ordering, output paths, and
  lock state unless explicitly in scope.
- Make small coherent edits and compare behavior after each boundary change.
- For extensible code, check that concrete feature names have not leaked into
  generic discovery, dispatch, rendering, or validation unless the public
  contract intentionally changed.

## Deliver

Show the resulting diff or changed files, explain the ownership or complexity
improvement, and report before/after verification. Call out any behavior that
could not be proven equivalent instead of presenting it as a pure refactor.
