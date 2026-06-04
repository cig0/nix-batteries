# Agent Instructions

This file defines reusable, model-agnostic working principles. Keep language,
framework, tool, and repository-specific directives in `AGENTS-REPOSITORY.md`.
That companion file is optional; when present, it should provide the project
overview, development commands, code style, and repository conventions.

## Instruction Discovery

- Before starting work, read `AGENTS-REPOSITORY.md` next to this file when it
  exists.
- Read any applicable nested `AGENTS.md` files and their companion
  `AGENTS-REPOSITORY.md` files before modifying files in their scope.
- Treat more specific instructions as additive. When instructions conflict,
  follow the instruction closest to the files being changed unless a
  higher-priority instruction says otherwise.

## Engineering Principles

- When principles conflict, prioritize them in this order: KISS, readability,
  ergonomics, performance, lean implementation, DRY, YAGNI, and widely adopted
  community standards.
- Use as few abstractions as possible. Prefer explicit naming and visible
  behavior.
- Preserve object agency: each object should own its state, behavior, and
  visible output. Do not make one object encode hidden decisions for another
  object when the boundary can be explicit.
- Prefer semantic, native values for internal implementation state. Preserve
  external protocol values exactly as expected by their consumers.
- Follow existing patterns and ownership boundaries. Keep changes scoped to the
  request and avoid unrelated refactors.

## Working State and Change Protection

- Before editing, inspect the current workspace state and any local changes that
  could be affected.
- Re-read a file from disk before editing it if its content may have changed
  since it was last read.
- Treat the current workspace state as authoritative when reconciling changes.
- Never revert, overwrite, delete, or discard existing user changes without
  explicit confirmation.
- Do not classify unexpected local changes as noise. They may have been made by
  the user alongside the current work.
- Never perform destructive, irreversible, privileged, or system-wide actions
  without explicit approval.
- Never install packages outside a project-local or sandboxed environment
  without explicit approval.

## Execution Rules

- Answer the exact request first. Do not expand scope unless explicitly asked.
- If requirements are ambiguous or missing, ask concise clarifying questions
  before proceeding.
- State assumptions only when they are non-obvious and affect the result.
- Prefer direct, minimal, actionable outputs.
- Use read-only inspection freely when it supports the task, but do not alter
  configuration, contact external services, or create externally visible
  changes unless separately allowed.

## Failure Handling

- On an unexpected or task-relevant command failure, unexpected output, or
  ambiguous result, stop immediately.
- Documented non-error exit statuses do not require stopping unless they affect
  the task.
- Report the failed command, its output, and the current workspace state. Wait
  for explicit user instructions before proceeding.
- Do not retry, work around, or continue past a failure silently.

### Resolved Operational Failures

- If a command fails because of a wrong inspection target, typo, stale path, or
  another operational mistake unrelated to the work under review, diagnose it
  explicitly and run the corrected command.
- Treat the failure as resolved only when the corrected command answers the
  same verification question satisfactorily.
- Do not classify failures as resolved when they reveal broken code, failed
  checks, missing dependencies, permission limits, destructive-risk
  uncertainty, ambiguous output, or a workspace change that needs user input.
- Mention resolved operational failures in the final response when they
  affected verification, but do not interrupt the workflow solely because the
  original command produced a misleading error.

## Verification and Delivery

- Check every changed file after editing to ensure it is correct and nothing is
  broken.
- Run the relevant focused checks for the files and behavior changed.
- Report checks that were not run or could not be completed.
- Never commit, publish, or otherwise make changes externally visible unless
  the user explicitly asks.
