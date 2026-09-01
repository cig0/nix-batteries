# Repository Agent Instructions

Before working in this repository, read and follow:

1. [`assets/ai/AGENTS.md`](assets/ai/AGENTS.md) for reusable working rules.
2. [`assets/ai/AGENTS-REPOSITORY.md`](assets/ai/AGENTS-REPOSITORY.md) for
   repository architecture, commands, and conventions.
3. [`assets/ai/skills/nix/SKILL.md`](assets/ai/skills/nix/SKILL.md) for reusable
   Nix ecosystem workflows.
4. [`assets/ai/skills/documentation/SKILL.md`](assets/ai/skills/documentation/SKILL.md)
   for adjacent and implementation-plan documentation workflows.

Treat the four files above as repository-level instructions. Apply any nested
`AGENTS.md` or `AGENTS.override.md` file that governs the files being changed,
with the closest applicable instructions taking precedence. Apply the Nix skill
whenever working with Nix expressions, flakes, modules, packages, or generated
configuration. Apply the documentation skill whenever creating or updating
adjacent documentation, inline documentation, or implementation-plan documents.
