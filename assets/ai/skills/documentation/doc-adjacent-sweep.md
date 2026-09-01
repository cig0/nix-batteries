# Adjacent Documentation Sweep

Use this workflow for adjacent READMEs and inline source documentation. For a
requested implementation plan, use
[implementation-plan.md](implementation-plan.md) instead.

## Core principles

Passive documentation, not active: the inline docs and READMEs should answer:
_what is this, where does it come from, where does it go_. Not: _how to add a
feature here_.

- “Adjacent” includes both `README.md` files and passive comments or type
  annotations inside code files when they explain what a module or function is,
  where its inputs come from, and where its outputs go.

- Provenance traces (`→`), option tables, and data flow descriptions — not
  tutorials.
- Existing structure preserved, just updated to reflect the new architecture.
- Terse but descriptive. Hand-holding, step-by-step examples if needed.
- Users should find joy in documentation, not fight it.

## Before editing

1. Read the nearest parent and sibling `README.md` files for the area in scope.
2. Identify what changed in code or architecture since the docs were last
   accurate.
3. Decide whether this directory needs its own README or whether the parent
   already routes readers clearly. See [doc-reference.md](doc-reference.md#readme-placement).
4. Do not expand into top-level historical docs or TODOs unless they send
   readers to stale paths.

## Sweep checklist

Copy and track progress:

```
Sweep progress:
- [ ] Scope: only adjacent READMEs for changed directories
- [ ] Placement: README justified or omitted per parent coverage
- [ ] Structure: existing sections preserved and updated, not replaced wholesale
- [ ] Passive voice: what / from / to — no feature-add tutorials
- [ ] Provenance: → traces, tables, or data-flow blocks where routing matters
- [ ] Brevity: terse but complete; step-by-step only where shape is non-obvious
- [ ] Links: "where to look next" points to live paths only
- [ ] Stale routes: fixed or removed in any touched README that referenced them
- [ ] Inline docs: module headers and function annotations are passive, not tutorials
```

## Update workflow

1. **Preserve structure.** Keep section headings and ordering that already work.
   Replace outdated facts; do not rewrite into a tutorial.
2. **Trace provenance.** Show how values, modules, or data cross boundaries:
   - Use `→` for indirect paths: `host profile → Modulon gate → renderer`.
   - Use tables for ownership or option namespaces.
   - Use `text` or `mermaid` flow blocks when multiple hops are easier to scan
     visually.
3. **State boundaries.** Separate what belongs here from what belongs elsewhere.
   Link to the owning README instead of duplicating its contract.
4. **Add examples sparingly.** Include a real configuration snippet or command
   only when the value shape, merge behavior, or consumer contract is not
   obvious from names and types alone.
5. **Close with navigation.** End with a short "where to look next" list of
   adjacent READMEs or architecture docs.

## Create workflow

Use when a new directory gains a non-obvious contract and the parent README
cannot route to it clearly.

1. Read two or three sibling READMEs in the same tree. Match their heading
   style, tone, and level of detail.
2. Open with a one-line title: path fragment + short role name.
3. Add only the sections the directory needs. Typical set:
   - What belongs here / what does not
   - How this is loaded or imported
   - Data flow or provenance
   - Real example (if non-obvious)
   - Where to look next
4. Omit empty or redundant sections. A three-section README is fine when it
   answers the three questions completely.

## Anti-patterns

Do not add:

- Step-by-step "how to add a feature" guides in adjacent READMEs
- Duplicated architecture essays that already live in a parent README
- READMEs in leaf directories whose only content would repeat the parent route
- Tutorial tone, marketing language, or historical narrative
- Broken or speculative links to paths not verified in the repository

## Verify

After editing:

1. Re-read the diff. Every changed sentence should reflect a real code or
   architecture fact.
2. Follow each `→` trace and "where to look next" link. Confirm targets exist.
3. Confirm no tutorial sections crept in under "examples" or "how to".
4. When code moved in the same change set, update the adjacent README in that
   same change set.
