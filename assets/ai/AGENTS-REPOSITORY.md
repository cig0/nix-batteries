# Repository Agent Guidelines

This file supplements the reusable `AGENTS.md` baseline and skills with
nix-batteries-specific architecture, compatibility, Git, and validation policy.

## Nix Ecosystem Baseline

- During development, do not treat a missing, stale, or changed `flake.lock` as
  a blocker. Do not change it unless the task requires it; report checks that
  cannot run without it.
- Apply `assets/ai/skills/nix/SKILL.md` and its required
  `nix-flake-maintenance.md` workflow to Nix expressions, flake wiring, public
  libraries, modules, fixtures, and generated shell behavior.
- Treat the reusable skill as the Nix ecosystem baseline. Keep only project
  ownership, local compatibility requirements, and repository-specific commands
  here.
- Apply `assets/ai/skills/documentation/SKILL.md` to adjacent documentation,
  inline documentation, and requested implementation-plan documents.

## Project Context

- This repository is a reusable Nix flake library toolkit. It is currently
  consumed by hoagie, but library code must remain useful outside that consumer.
- `flake.nix` defines plain outputs over a single nixpkgs input.
  `batteriesLib` maps each public export directly onto its implementation under
  `libraries/`; `checks` and `formatter` fan out per supported system.
  Library source lives under `libraries/` and includes Modulon, Modulette,
  guard-flake-input, help-legend decorators, themes, and small runtime helper
  generators.
- Some public helpers generate terminal behavior for POSIX-compatible shells,
  Fish, and Nushell. Apply the reusable Nix generated-shell workflow whenever
  those payloads change.

## Required Component Reading

- `libraries/auto-discover/modulon/` owns Nix module auto-discovery. Read its
  `README.md` and the focused documents under `docs/` before changing discovery
  behavior.
- `libraries/auto-discover/modulette/` owns header-validated passive module
  discovery. Read its adjacent `README.md` before changing its contract.
- `libraries/guard-flake-input/` owns optional flake-input handling.
- `libraries/decorators/help-legend/` owns help-screen layout and native shell
  renderers.
- `libraries/themes/` owns true-color theme data, validation, resolution, and
  the theme option module.
- `libraries/toolbox/` owns small reusable shell and runtime generators.
- `fixtures/` contains lightweight public-behavior fixtures. Keep them small,
  deterministic, and focused on one contract.

## Git Workflow

- Always add `--no-pager` when using `git`.
- Before editing, run `git --no-pager status --short --branch` and inspect local
  changes that could be affected.
- If the current branch is `main`, `master`, `trunk`, or another protected or
  default branch, create a descriptive task branch before changing files unless
  the user explicitly instructs otherwise.
- Treat a detached `HEAD` as unsafe for edits. Create or switch to a
  task-specific branch before changing files unless explicitly instructed
  otherwise.
- When possible, identify the default branch from repository metadata instead
  of assuming its name.
- If already on a task-specific branch, continue there unless told otherwise.
- Never run Git operations that may discard uncommitted work without explicit
  approval, including `git reset --hard`, `git clean -f`, `git clean -fd`,
  `git checkout -- <file>`, `git restore <file>`, `git stash pop`,
  `git stash drop`, or `git switch` with a dirty working tree.
- Never modify Git configuration or bypass hooks and policies. Do not use
  `--no-verify`.
- Commits, pushes, pull requests, and force pushes require explicit user
  instruction. Never force push to a protected or default branch.

## Nix And Repository Style

- Use `nixfmt-rfc-style`, exposed by the flake formatter, for Nix code.
- Use block comments (`/* ... */`) for Nix comments of four lines or more. Use
  `#` for inline comments or at most three consecutive comment lines.
- Keep library functions explicit about their inputs. Prefer arguments over
  hidden access to consumer-specific paths, option names, or repository
  layouts.
- Keep public `self.batteriesLib` names and return contracts stable unless the user
  explicitly requests a breaking API change.
- When adding behavior to a public helper, add or update a focused fixture under
  `fixtures/` and wire it into `checks`.
- Provider-owned public metadata must be explicit. Consumers must not need to
  infer provenance from a library attribute name or source-tree convention.

## Validation

- Run the reusable Nix parse, format, focused-evaluation, and generated-shell
  checks appropriate to the changed boundary.
- Run `nix flake check` after changing exported library behavior, fixtures, or
  flake outputs. Use `nix flake check --all-systems --no-build` to evaluate the
  supported system matrix from one host when practical.
- Run focused `nix eval` smoke checks when public `self.batteriesLib` names, return
  shapes, or provider metadata change.
- Report any supported system or generated shell that was not exercised.
