# Repository Agent Guidelines

This file supplements `AGENTS.md` with repository-specific context and
implementation rules. Read and follow both files.

## Project Context

- This repository is a cross-platform Nix orchestration flake and a single
  source of truth for NixOS, GNU/Linux, and macOS hosts.
- Nix is the primary implementation language. The flake also renders shell
  behavior for POSIX-compatible shells, Fish, and Nushell.
- Keep Nix, shell syntax, and system ownership visible. Do not add abstractions
  whose main purpose is to hide those semantics from the author.
- Documentation lives close to the code. Read the nearest relevant `README.md`
  before changing an unfamiliar area.
- Treat `config/shortcuts/` only as local navigation aids. Do not use it as a
  configuration source of truth.

## Required Architecture Reading

- Before modifying Home Manager modules, NixOS modules, shared modules, or
  shared data modules, read `docs/HM-FIRST-NIXOS.md`.
- Before changing evaluation lanes, module loading, or shared data flow, read
  `docs/ARCHITECTURE.md`.
- Treat those documents as binding repository policy for module ownership,
  namespace boundaries, and data flow.

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
- Modules must reference normalized flake inputs through `_inputs`, not raw
  `inputs` or channel-suffixed input names. See `flake.nix.d/README.md`.
- Preserve the distinction between loaded modules and passive shared data. See
  `config/shared/README.md` before moving code across that boundary.

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

- Follow `docs/VALIDATION.md` and keep checks focused on the code touched.
- Parse each changed `.nix` file with `nix-instantiate --parse`.
- Check Nix formatting with `nix fmt -- --check <changed-files>`.
- Run relevant evaluation smoke checks when wiring, modules, or flake outputs
  change.
- Parse isolated generated shell snippets with their target runtime when
  practical.
- Test changes on every affected platform when practical, and report any
  platform that was not tested.
