# Repository Agent Guidelines

This file supplements `AGENTS.md` with repository-specific context and
implementation rules. Read and follow both files.

## Project Context

- This repository is a reusable Nix flake library toolkit. It is commonly
  consumed by `nix-ignition`, but library code must stay useful outside that
  consumer.
- Public library exports live under `self.igniteLibs` in `flake.nix`: Modulon,
  Modulette, guard-flake-input, help-legend decorators, themes, and small
  runtime helper generators.
- Nix is the primary implementation language. Some library helpers generate
  shell snippets for POSIX-compatible shells, Fish, and Nushell.
- Keep Nix and shell semantics visible. Do not add abstractions whose main
  purpose is to hide those semantics from the caller.
- Documentation lives close to the component it describes. Read the relevant
  component `README.md` before changing unfamiliar code.

## Component Boundaries

- `modulon/` owns Nix module auto-discovery. Read `modulon/README.md` and the
  focused docs under `modulon/docs/` before changing discovery behavior.
- `modulette/` owns header-validated data-module discovery.
- `guard-flake-input/` owns optional input handling.
- `decorators/help-legend/` owns help-screen layout and shell renderers.
- `themes/` owns ANSI palette/theme data and the theme option module.
- `toolbox/` owns small reusable shell/runtime code generators.
- `fixtures/` contains lightweight fixtures used by flake checks. Keep fixtures
  small, deterministic, and focused on public library behavior.

## Git Workflow

- Always add `--no-pager` when using `git`.
- Before editing, run `git --no-pager status --short` and inspect local changes
  that could be affected.
- Show the current branch before making significant changes.
- If the current branch is `main`, `master`, `trunk`, or another protected or
  default branch, create a descriptive task branch before changing files unless
  the user explicitly instructs otherwise.
- Treat a detached `HEAD` as unsafe for edits. Create or switch to a
  task-specific branch before changing files unless explicitly instructed
  otherwise.
- When possible, identify the default branch with
  `git symbolic-ref refs/remotes/origin/HEAD` or repository metadata instead of
  assuming its name.
- If already on a task-specific branch, continue there unless told otherwise.
- Never run Git operations that may discard uncommitted work without explicit
  approval, including `git reset --hard`, `git clean -f`, `git clean -fd`,
  `git checkout -- <file>`, `git restore <file>`, `git stash pop`,
  `git stash drop`, or `git switch` with a dirty working tree.
- Never modify Git configuration or bypass commit hooks and policies. Do not
  use `--no-verify`.
- Commits, pushes, and pull requests require explicit user instruction. Never
  force push to a protected or default branch.

## Nix and Repository Style

- Use `nixfmt-rfc-style`, exposed by the flake formatter, for Nix code.
- Use block comments (`/* ... */`) for Nix comments of four lines or more. Use
  `#` for inline comments or at most three consecutive comment lines.
- Keep library functions explicit about their inputs. Prefer arguments over
  hidden access to consumer-specific paths or option names.
- Keep public `self.igniteLibs` names stable unless the user explicitly asks for a
  breaking API change.
- When adding behavior to a public helper, add or update a focused fixture under
  `fixtures/` and wire it into `checks`.

## Terminal Output Policy

This policy is the repository-specific application of the object-agency
principle from `AGENTS.md`.

- Treat each terminal content object as owning only its own visible content. It
  must not decide whether a later object starts on a new line by hiding a
  trailing `\n` at the end of its text string.
- For `printf`, `printf '%b'`, `print --no-newline`, and equivalent emitters,
  prefer leading newlines on the content object that owns the spacing, or use a
  separate explicit newline emitter such as `printf '%b' "\n"` when the layout
  boundary is its own object.
- Preserve unterminated output fragments only when they are parts of one
  logical terminal object, such as a progress prefix followed by its result on
  the same line.
- Do not use `echo -e`. Use `printf '%b'` when escape-sequence interpretation is
  required, and make any line ending explicit.
- Apply this policy to executable code and code examples in Markdown
  documentation.
- Do not apply this policy to structural newlines in data, parsing, generated
  file content, format strings such as `%s\n`, or separators such as
  `concatStringsSep "\n"`.

## Validation

- Parse each changed `.nix` file with `nix-instantiate --parse`.
- Check Nix formatting with `nix fmt -- --check <changed-files>`.
- Run `nix flake check` after changing exported library behavior, fixtures, or
  flake outputs. Use `nix flake check --all-systems --no-build` to evaluate the
  full supported system matrix from one host.
- Run focused `nix eval` smoke checks when changing public `self.igniteLibs` names or
  return shapes.
- Parse isolated generated shell snippets with their target runtime when
  practical.
