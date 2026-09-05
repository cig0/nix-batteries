# Documentation Reference

Supporting templates and examples for adjacent README work. Load when authoring
or restructuring a README.

## README placement

```
Does the parent README already name this directory and state its role?
├─ Yes, and readers can route without ambiguity → no leaf README
└─ No, or the directory owns a distinct contract → add or update README here
```

Leaf directories that only hold implementation files imported by a parent module
usually do not need their own README.

## Inline documentation in code files

Use when the repository contains code modules whose contract is not already
clear from names alone.

- Add module headers that answer: what is this file, where do its inputs come
  from, where do its outputs go.
- Add function annotations (`---@param`, `---@return`, etc.) for non-trivial
  public or cross-module boundaries.
- Keep comments passive: state contract and provenance, not implementation
  steps.
- Prefer a precise module, function, or variable name over a comment that merely
  translates an ambiguous name. Comments should add ownership, rationale, or
  provenance that the code cannot state directly.
- Cite authoritative producers or loaders. Do not reconstruct provenance from
  naming conventions when the source can provide it explicitly.

Good:

```lua
--- Action schema validation and execution.
-- menu item `action` tables → this module → runtime dispatch.
```

Bad:

```lua
--- How to add a new action:
-- 1. Add a case to `M.validate`.
-- 2. Add a case to `M.execute`.
-- 3. Return `{ close = true }`.
```

Tutorial steps belong in a contributor guide, not adjacent code comments.

## Section templates

Pick sections that answer the three questions. Omit sections with nothing useful
to say.

### Title line

```markdown
# <path-fragment> — <Short Role Name>
```

### What belongs / what does not

```markdown
## What belongs here

- <concise ownership bullets>

## What does not belong here

- <boundary bullets with → to owning README when helpful>
```

### Loading and provenance

```markdown
## How this is loaded

<one short paragraph or bullet list with → traces>
```

### Data flow

Use `text` for simple hops; use `mermaid` when branching or parallel consumers
make a diagram faster to scan.

```markdown
## Data flow

\`\`\`text

<source>
→ <intermediate>
→ <consumer>
\`\`\`
```

### Real example

Reserve for non-obvious value shapes or cross-file wiring.

```markdown
## Real example

\`\`\`<lang>
<minimal real snippet>
\`\`\`

<one sentence tying snippet to producer and consumer>
```

### Navigation close

```markdown
## Where to look next

- `<relative-path>` — <why go there>
```

## Provenance trace patterns

| Pattern                            | Use when                                    |
| ---------------------------------- | ------------------------------------------- |
| `a.nix → b.nix`                    | Value forwarded or transformed across files |
| `host profile → option → renderer` | Configuration crosses module boundaries     |
| `catalogue → module → output`      | Passive data becomes active config          |
| `caller args → shared module`      | Multiple valid upstream callers             |

Keep traces factual and short. One hop per line in multi-step flows.

## Good vs bad

### Passive (good)

```markdown
## Data flow

\`\`\`text
host profile
→ myOptions.hm.<app>.\*
→ gated implementation
→ native Home Manager interface
\`\`\`

Passive defaults and reusable payloads → shared data modules.
Host-specific values → host profiles.
```

Answers what crosses the boundary and where each concern lives.

### Active / tutorial (bad)

```markdown
## Adding a new application module

1. Create `my-app.nix` in this directory.
2. Add an enable option.
3. Import it from `default.nix`.
4. Run `home-manager switch`.
```

Belongs in a contributor guide or skill workflow, not an adjacent README.

### Terse but descriptive (good)

```markdown
`../modulon.nix` auto-discovers this directory for Home Manager. The NixOS
package renderer imports `packages.nix` directly; other shared values cross the
NixOS freeform bridge and are typed in the HM evaluation.
```

### Hand-holding when needed (good)

Use when flag semantics, merge behavior, or shell-specific rendering differ:

```markdown
Non-update commands (`hsd`, `hs`):
`hsf --no-ack -- --override-input nix-sidecar ../path`
→ `_extra_flags` = `[--override-input, nix-sidecar, ../path]`
→ command: `nh home switch ... --no-update-lock-file -- --impure ...`
```

The step-by-step form is justified because the contract is non-obvious.

## Relationship to Nix provenance comments

| Surface                           | Owns                                                                |
| --------------------------------- | ------------------------------------------------------------------- |
| Adjacent `README.md`              | Directory contract, data flow, cross-directory routing              |
| Inline Nix `#` / `/* */` comments | Non-obvious args, forwarded attrs, input normalization at call site |

Do not move call-site context into a README when the comment beside the
argument is the clearest location. Do not duplicate README routing tables into
Nix source comments.

## Quality bar

Documentation succeeds when a reader can answer in under a minute:

1. **What** is this directory or module?
2. **Where does it come from** — imports, loaders, upstream options?
3. **Where does it go** — consumers, outputs, adjacent owners?

If any answer requires a tutorial, the README is doing too much or the code
boundary needs simplification — not a longer README.
